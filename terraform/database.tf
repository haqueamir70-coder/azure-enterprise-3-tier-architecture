# Azure SQL Server and database
# Supply the administrator password securely via TF_VAR_sql_admin_password
# or a protected secret store. Never commit the value to source control.

resource "azurerm_mssql_server" "sql_server" {
  name                          = "azure3tier-sql-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "database" {
  name      = "enterprise-database"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic"
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                 = "sql-private-dns-link"
  private_dns_zone_id  = azurerm_private_dns_zone.sql.id
  virtual_network_id   = azurerm_virtual_network.vnet.id
  registration_enabled = false
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-azure3tier-sql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-azure3tier-sql"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}
