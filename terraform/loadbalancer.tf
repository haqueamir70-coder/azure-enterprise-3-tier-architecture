# Azure Load Balancer

resource "azurerm_public_ip" "lb_ip" {

  name = "azure3tier-lb-public-ip"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"

}


resource "azurerm_lb" "main" {

  name = "azure3tier-load-balancer"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name


  frontend_ip_configuration {

    name = "PublicIPAddress"

    public_ip_address_id = azurerm_public_ip.lb_ip.id

  }

}
