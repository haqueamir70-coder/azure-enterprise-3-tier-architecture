# Azure Provider Configuration

provider "azurerm" {

  features {}

}


# Resource Group

resource "azurerm_resource_group" "main" {

  name     = "azure-3tier-demo-rg"
  location = "East US"

}


# Virtual Network

resource "azurerm_virtual_network" "vnet" {

  name                = "azure-3tier-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

}
