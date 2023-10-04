# Fetch admin-username , admin-password, domain-password,log-analytics-id,log-analytics-key,storage-account-name,storage-account-key from key vault
data "azurerm_key_vault" "terraformvault" {
  name                = var.keyvault
  resource_group_name = var.keyvaultrg
}

data "azurerm_key_vault_secret" "admin-username" {
  name         = "admin-username"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "admin-password" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "domain-pwd" {
  name         = "domain-pwd"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "log-analytics-id" {
  name         = "log-analytics-id"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "log-analytics-key" {
  name         = "log-analytics-key"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "storage-account-name" {
  name         = "storage-account-name"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}


data "azurerm_key_vault_secret" "storage-account-access-key" {
  name         = "storage-account-access-key"
  key_vault_id = data.azurerm_key_vault.terraformvault.id
}

data "azurerm_storage_account" "diagstorage2" {
  name                = var.bootdiag_SA
  resource_group_name = var.bootdiag_RG
}
#***********************************************************************************
# Availability set App servers
resource "azurerm_availability_set" "APP-AS" {
  name                         = "${var.rg}-App-AS"
  location                     = azurerm_resource_group.prodrg.location
  resource_group_name          = azurerm_resource_group.prodrg.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 10
  managed                      = true
  tags                         = var.tags
}


# Availability set Web Servers
resource "azurerm_availability_set" "WEB-AS" {
  name                         = "${var.rg}-Web-AS"
  location                     = azurerm_resource_group.prodrg.location
  resource_group_name          = azurerm_resource_group.prodrg.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 10
  managed                      = true
  tags                         = var.tags
}

# NIC Card for respective WEB Servers
resource "azurerm_network_interface" "webnic" {
  for_each = var.vmnameweb
  # count               = length(each.value.nic)
  name                = join("-", [each.value.name, "NIC0"])
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  tags                = var.tags

  ip_configuration {
    name                          = "IPconfig1"
    subnet_id                     = azurerm_subnet.websubnet.id
    private_ip_address_allocation = "dynamic"
  }
}

# NIC Card for respective APP Servers
resource "azurerm_network_interface" "appnic" {
  for_each = var.vmnameapp
  # count               = length(each.value.nic)
  name                = join("-", [each.value.name, "NIC0"])
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  tags                = var.tags

  ip_configuration {
    name                          = "IPconfig1"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "dynamic"

  }
}

# Virtual Machine code for the WEB servers
resource "azurerm_virtual_machine" "webvm" {
  for_each = var.vmnameweb
  # count                 = length(var.vmnameweb)
  name                  = each.value.name
  location              = azurerm_resource_group.prodrg.location
  resource_group_name   = azurerm_resource_group.prodrg.name
  network_interface_ids = [azurerm_network_interface.webnic[each.key].id]
  availability_set_id   = azurerm_availability_set.WEB-AS.id
  vm_size               = each.value.size
  tags                  = var.tags

  boot_diagnostics {
    enabled     = "true"
    storage_uri = data.azurerm_storage_account.diagstorage2.primary_blob_endpoint
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  storage_os_disk {
    name              = join("-", [each.value.name, "OSDisk"])
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = join("-", [each.value.name, "DataDisk1"])
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = each.value.disk
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

# Virtual Machine code for the APP servers
resource "azurerm_virtual_machine" "appvm" {
  for_each = var.vmnameapp
  # count                 = length(var.vmnameapp)
  name                  = each.value.name
  location              = azurerm_resource_group.prodrg.location
  resource_group_name   = azurerm_resource_group.prodrg.name
  network_interface_ids = [azurerm_network_interface.appnic[each.key].id]
  availability_set_id   = azurerm_availability_set.APP-AS.id
  vm_size               = each.value.size
  tags                  = var.tags

  boot_diagnostics {
    enabled     = "true"
    storage_uri = data.azurerm_storage_account.diagstorage2.primary_blob_endpoint
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  storage_os_disk {
    name              = join("-", [each.value.name, "OSDisk"])
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  storage_data_disk {
    name              = join("-", [each.value.name, "DataDisk1"])
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = each.value.disk
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

# Extension: Add WEB server to susdmz.local domain

resource "azurerm_virtual_machine_extension" "WebDomainJoin" {
  for_each = var.vmnameweb
  # count                = length(var.vmnameweb)
  name = "DomainJoin"
  # virtual_machine_id   = element(azurerm_virtual_machine.webvm.*.id, count.index)
  virtual_machine_id   = azurerm_virtual_machine.webvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  tags                 = var.tags


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
  depends_on         = ["azurerm_virtual_machine.webvm"]
}

# Extension: Add APP server to susdmz.local domain
resource "azurerm_virtual_machine_extension" "APPDomainJoin" {
  for_each = var.vmnameapp
  # count                = length(var.vmnameapp)
  name = "DomainJoin"
  # virtual_machine_id   = element(azurerm_virtual_machine.appvm.*.id, count.index)
  virtual_machine_id   = azurerm_virtual_machine.appvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  tags                 = var.tags


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
  depends_on         = ["azurerm_virtual_machine.appvm"]
}


# Extension: BGInfo WEB Servers
resource "azurerm_virtual_machine_extension" "WEBBGInfo" {
  for_each = var.vmnameweb
  # count                = length(var.vmnameweb)
  name                 = "BGInfo"
  virtual_machine_id   = azurerm_virtual_machine.webvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"
  tags                 = var.tags
}

# Extension: BGInfo APP Servers
resource "azurerm_virtual_machine_extension" "AppBGInfo" {
  for_each = var.vmnameapp
  # count                = length(var.vmnameapp)
  name                 = "BGInfo"
  virtual_machine_id   = azurerm_virtual_machine.appvm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"
  tags                 = var.tags
}



# Extension: To add Web server patching log annalytics workspace
resource "azurerm_virtual_machine_extension" "webmmaagent" {
  for_each = var.vmnameweb
  # count                      = length(var.vmnameweb)
  name                       = "webmmaagent"
  virtual_machine_id         = azurerm_virtual_machine.webvm[each.key].id
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


# Extension: To add APP server patching log annalytics workspace
resource "azurerm_virtual_machine_extension" "appmmaagent" {
  for_each = var.vmnameapp
  # count                      = length(var.vmnameapp)
  name                       = "appmmaagent"
  virtual_machine_id         = azurerm_virtual_machine.appvm[each.key].id
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

