terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.19"
    }
  }
}

provider "azurerm" {
  features {}
}