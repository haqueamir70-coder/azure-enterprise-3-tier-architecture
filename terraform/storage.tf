# Azure Storage Account

resource "azurerm_storage_account" "storage" {

  name = "azure3tierstorage001"

  resource_group_name = azurerm_resource_group.main.name

  location = azurerm_resource_group.main.location

  account_tier = "Standard"

  account_replication_type = "LRS"


  min_tls_version = "TLS1_2"

}


# Storage Container

resource "azurerm_storage_container" "backup" {

  name = "backup-container"

  storage_account_name = azurerm_storage_account.storage.name

  container_access_type = "private"

}
