# Web Tier Subnet

resource "azurerm_subnet" "web_subnet" {

  name = "web-subnet"

  resource_group_name = azurerm_resource_group.main.name

  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.1.0/24"]

}


# Application Tier Subnet

resource "azurerm_subnet" "app_subnet" {

  name = "app-subnet"

  resource_group_name = azurerm_resource_group.main.name

  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.2.0/24"]

}


# Database Tier Subnet

resource "azurerm_subnet" "database_subnet" {

  name = "database-subnet"

  resource_group_name = azurerm_resource_group.main.name

  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.3.0/24"]

}


# Network Security Group

resource "azurerm_network_security_group" "main" {

  name = "three-tier-nsg"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name


  security_rule {

    name = "Allow-HTTP"

    priority = 100

    direction = "Inbound"

    access = "Allow"

    protocol = "Tcp"

    source_port_range = "*"

    destination_port_range = "80"

    source_address_prefix = "*"

    destination_address_prefix = "*"

  }

}
