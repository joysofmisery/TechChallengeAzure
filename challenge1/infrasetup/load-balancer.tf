# LoadBalancer NIC Configuration


# Internal Load Balancer for Application Servers
resource "azurerm_lb" "lb" {
  name                = "${var.clientname}-InternalLB"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  sku                 = "standard"
  tags                = var.tags




  frontend_ip_configuration {
    name                          = "PrivateIPAddress"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "static"

  }
}

# LB BackendPool Creation
resource "azurerm_lb_backend_address_pool" "lbpool" {
  resource_group_name = azurerm_resource_group.prodrg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${var.clientname}-BackEndAddressPool"
}


# LB Rules configuration for HTTP 
resource "azurerm_lb_rule" "lbrulehttp" {
  resource_group_name            = azurerm_resource_group.prodrg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lbpool.id
  probe_id                       = azurerm_lb_probe.httpprobe.id
  load_distribution              = "SourceIPProtocol"

}

# LB Rules configuration for HTTPS
resource "azurerm_lb_rule" "lbrulehttps" {
  resource_group_name            = azurerm_resource_group.prodrg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PrivateIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lbpool.id
  probe_id                       = azurerm_lb_probe.httpsprobe.id
  load_distribution              = "SourceIPProtocol"

}

#LB Health Probe configuration for HTTP
resource "azurerm_lb_probe" "httpprobe" {

  resource_group_name = azurerm_resource_group.prodrg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "HTTP-PROBE"
  port                = 80

}

#LB Health Probe configuration for HTTPS
resource "azurerm_lb_probe" "httpsprobe" {
  resource_group_name = azurerm_resource_group.prodrg.name
  loadbalancer_id     = azurerm_lb.lb.*.id
  name                = "HTTPS-PROBE"
  port                = 443

}

# Adding Application Servers to the backend Pool of LB
resource "azurerm_network_interface_backend_address_pool_association" "lbassociation2" {
for_each = var.vmnameapp
  network_interface_id    = azurerm_network_interface.appnic[each.key].id
  ip_configuration_name   = "IPconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbpool.id

}