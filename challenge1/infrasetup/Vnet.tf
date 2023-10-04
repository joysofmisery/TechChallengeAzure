resource "azurerm_resource_group" "prodrg" {
  name     = var.prodresourcegroup
  location = var.location
  tags     = var.tags
}

# data "azurerm_resource_group" "ddosrg" {
#   name = var.ddosrg

# }

# data "azurerm_network_ddos_protection_plan" "ddosplan" {
#   name                = var.ddosname
#   resource_group_name = data.azurerm_resource_group.ddosrg.name
# }


resource "azurerm_virtual_network" "vnet" {
  name                = "${var.clientname}_VNET"
  address_space       = [var.vnetaddress]
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  dns_servers         = ["10.0.0.4", "10.0.0.6"]

#   ddos_protection_plan {
#     enable = true
#     id     = data.azurerm_network_ddos_protection_plan.ddosplan.id
#   }
}

resource "azurerm_subnet" "websubnet" {
  name                 = "${var.clientname}_webSubnet"
  resource_group_name  = azurerm_resource_group.prodrg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.websubnetaddress]
}
resource "azurerm_subnet" "appsubnet" {
  name                 = "${var.clientname}_appSubnet"
  resource_group_name  = azurerm_resource_group.prodrg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appsubnetaddress]
}
resource "azurerm_subnet" "dbsubnet" {
  name                 = "${var.clientname}_dbSubnet"
  resource_group_name  = azurerm_resource_group.prodrg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.dbsubnetaddress]
}
resource "azurerm_nat_gateway" "natgateway" {
  name                    = "${var.clientname}_natgateway"
  location                = azurerm_resource_group.prodrg.location
  resource_group_name     = azurerm_resource_group.prodrg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  # zones                   = ["3"]
}
resource "azurerm_public_ip" "natgwip" {
  name                = "${var.clientname}_natpip"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  # zones                   = ["3"]
}
resource "azurerm_nat_gateway_public_ip_association" "natgatewayiplink" {
  nat_gateway_id       = azurerm_nat_gateway.natgateway.id
  public_ip_address_id = azurerm_public_ip.natgwip.id
}
resource "azurerm_subnet_nat_gateway_association" "natweblink" {
  subnet_id      = azurerm_subnet.websubnet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
  depends_on = [azurerm_network_interface.appnic]
}
resource "azurerm_subnet_nat_gateway_association" "natapplink" {
  subnet_id      = azurerm_subnet.appsubnet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
  depends_on = [azurerm_network_interface.appnic]
}
# NSG for DB Subnet
resource "azurerm_network_security_group" "nsgdb" {
  name                = "${var.clientname}_NSG-DB"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name  = azurerm_resource_group.prodrg.name
  tags                = var.tags

}
# NSG For the App&Web Subnet
resource "azurerm_network_security_group" "nsgapp" {
  name                = "${var.clientname}_NSG-APP"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name  = azurerm_resource_group.prodrg.name
  tags                = var.tags
}
resource "azurerm_network_security_group" "nsgweb" {
  name                = "${var.clientname}_NSG-WEB"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name  = azurerm_resource_group.prodrg.name
  tags                = var.tags
}
resource "azurerm_subnet_network_security_group_association" "webnsglink" {
  subnet_id                 = azurerm_subnet.websubnet.id
  network_security_group_id = azurerm_network_security_group.nsgweb.id
  depends_on = [azurerm_subnet_nat_gateway_association.natprodlink]
}
resource "azurerm_subnet_network_security_group_association" "appnsglink" {
  subnet_id                 = azurerm_subnet.appsubnet.id
  network_security_group_id = azurerm_network_security_group.nsgapp.id
  depends_on = [azurerm_subnet_nat_gateway_association.natprodlink]
}
resource "azurerm_subnet_network_security_group_association" "dbnsglink" {
  subnet_id                 = azurerm_subnet.dbsubnet.id
  network_security_group_id = azurerm_network_security_group.nsgdb.id
}
############################################## PEERING BETWEEN ADDS AND PROD VNET###########################################################

data "azurerm_resource_group" "HUb" {
  name = "HUB01"
}

data "azurerm_virtual_network" "Hub_vnet" {
  name                = "HUB01-vnet"
  resource_group_name = data.azurerm_resource_group.Hub.name
}

#**************************************************************************************************************************************
# Vnet peering1
resource "azurerm_virtual_network_peering" "Hub-ClientPeering" {
  name                         = "Hub-${var.clientname}"
  resource_group_name          = data.azurerm_resource_group.HUb.name
  virtual_network_name         = data.azurerm_virtual_network.Hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

#**************************************************************************************************************************************
# Vnet peering2
resource "azurerm_virtual_network_peering" "ClientPeering-ADDS" {
  name                         = "${var.clientname}-Hub"
  resource_group_name          = azurerm_resource_group.prodrg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.Hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}