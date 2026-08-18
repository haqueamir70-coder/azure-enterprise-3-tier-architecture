# Azure Key Vault

resource "azurerm_key_vault" "keyvault" {

  name = "azure3tier-keyvault001"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name


  tenant_id = data.azurerm_client_config.current.tenant_id


  sku_name = "standard"


  soft_delete_retention_days = 7

}


# Current Azure Client Information

data "azurerm_client_config" "current" {}
