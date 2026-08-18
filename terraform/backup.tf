# Azure Recovery Services Vault

resource "azurerm_recovery_services_vault" "backup" {

name = "azure3tier-backup-vault"

location = azurerm_resource_group.main.location

resource_group_name = azurerm_resource_group.main.name

sku = "Standard"

}
