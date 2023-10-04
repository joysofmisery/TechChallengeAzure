terraform {
  backend "azurerm" {

    resource_group_name  = "RG-Storage"
    storage_account_name = "saterraform"
    container_name       = "remotestate"
    key                  = "tier3.tfstate"

  }
}