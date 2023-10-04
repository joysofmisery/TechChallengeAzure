#Checking Resource Group Dependency
data "azurerm_resource_group" "dbrg" {
  name = var.rg
 depends_on = [azurerm_resource_group.prodrg]
}
#*****************************************************************************
# Availablity set for DB tier
resource "azurerm_availability_set" "DB-AS" {
  name                         = "${var.rg}-DB-AS"
  location                     = azurerm_resource_group.prodrg.location
  resource_group_name          = azurerm_resource_group.prodrg.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 10
  managed                      = true
  tags                         = var.tags
}

# NIC Card for DB Server
resource "azurerm_network_interface" "nicdb" {
for_each = var.dbvm
  name                = "${each.value.name}-Nic1"
  location            = data.azurerm_resource_group.dbrg.location
  resource_group_name = data.azurerm_resource_group.dbrg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dbsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine code for the DB server
resource "azurerm_virtual_machine" "dbvm" {
for_each = var.dbvm
  name                  = each.value.name
  location              = data.azurerm_resource_group.dbrg.location
  resource_group_name   = data.azurerm_resource_group.dbrg.name
  network_interface_ids = [azurerm_network_interface.nicdb[each.key].id]
  availability_set_id   = azurerm_availability_set.DB-AS.id
  vm_size               = each.value.size
  tags                  = var.tags
  boot_diagnostics {
    enabled     = "true"
    storage_uri = data.azurerm_storage_account.diagstorage2.primary_blob_endpoint
  }

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2019"
    sku       = "Web"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${each.value.name}-DataDisk1"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = each.value.disk_db
  }

  storage_data_disk {
    name              = "${each.value.name}-DataDisk2"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 1
    disk_size_gb      = each.value.disk_log
  }

  storage_data_disk {
    name              = "${each.value.name}-DataDisk3"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 2
    disk_size_gb      = each.value.disk_backup
  }


  os_profile {
    computer_name  = each.value.name
    admin_username = data.azurerm_key_vault_secret.admin-username.value
    admin_password = data.azurerm_key_vault_secret.admin-password.value
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

}

# Extension: Add DB server to susdmz.local domain

resource "azurerm_virtual_machine_extension" "DBDomainJoin" {
for_each = var.dbvm 
  name                 = "DomainJoin"
  virtual_machine_id   = azurerm_virtual_machine.dbvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"


  settings           = <<SETTINGS
    {
        "Name": "susdmz.local",
        "OUPath": "OU=AADDC Computers,DC=susdmz,DC=local",
        "User": "susdmz.local\\svc.amit",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${data.azurerm_key_vault_secret.domain-pwd.value}"
    }
  PROTECTED_SETTINGS
  depends_on         = [azurerm_virtual_machine.dbvm]
}


# Extension: BGInfo
resource "azurerm_virtual_machine_extension" "DBBGInfo" {
for_each = var.dbvm
  name                 = "BGInfo"
  virtual_machine_id   = azurerm_virtual_machine.dbvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"
}

# Extension: To add VM in server patching log annalytics workspace
resource "azurerm_virtual_machine_extension" "dbmmaagent" {
for_each = var.dbvm   
  name                       = "dbmmaagent"
  virtual_machine_id         = azurerm_virtual_machine.dbvm[each.key].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  settings                   = <<SETTINGS
{
"workspaceId": "${data.azurerm_key_vault_secret.log-analytics-id.value}"
}
SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
{
"workspaceKey": "${data.azurerm_key_vault_secret.log-analytics-key.value}"
}
PROTECTED_SETTINGS
}