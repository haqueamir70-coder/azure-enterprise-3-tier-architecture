# Azure Front Door WAF Configuration

resource "azurerm_cdn_frontdoor_profile" "frontdoor" {

  name = "azure3tier-frontdoor"

  resource_group_name = azurerm_resource_group.main.name

  sku_name = "Standard_AzureFrontDoor"

}


resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {

  name = "azure3tier-waf-policy"

  resource_group_name = azurerm_resource_group.main.name

  sku_name = "Standard_AzureFrontDoor"

  enabled = true

  mode = "Prevention"

}
