# Azure Storage Account — private blob access
resource "azurerm_storage_account" "storage" {
  name                          = "azure3tierstorage001"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  shared_access_key_enabled    = false
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "backup" {
  name                  = "backup-container"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-private-dns-link"
  private_dns_zone_id   = azurerm_private_dns_zone.blob.id
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-azure3tier-blob"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-azure3tier-blob"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
