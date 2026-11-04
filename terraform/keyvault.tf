# Azure Key Vault — private access only
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                          = "azure3tier-kv-${random_string.suffix.result}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true

  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                 = "key-vault-private-dns-link"
  private_dns_zone_id  = azurerm_private_dns_zone.key_vault.id
  virtual_network_id   = azurerm_virtual_network.vnet.id
  registration_enabled = false
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-azure3tier-keyvault"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-azure3tier-keyvault"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}
