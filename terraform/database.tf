# Azure SQL Server and database
# Supply the administrator password securely at plan/apply time, for example
# via TF_VAR_sql_admin_password in your local shell or a protected CI secret.
# Do not commit the value to source control.

resource "azurerm_mssql_server" "sql_server" {
  name                         = "azure3tier-sql-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  minimum_tls_version = "1.2"
}

resource "azurerm_mssql_database" "database" {
  name      = "enterprise-database"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic"
}

# This rule enables Azure services through the special 0.0.0.0 rule.
# Review whether it is needed; prefer private connectivity and a narrowly
# scoped firewall policy for real deployments.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
