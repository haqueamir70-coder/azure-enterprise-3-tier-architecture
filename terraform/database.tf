# Azure SQL Server

resource "azurerm_mssql_server" "sql_server" {

  name = "azure3tier-sql-server"

  resource_group_name = azurerm_resource_group.main.name

  location = azurerm_resource_group.main.location

  version = "12.0"

  administrator_login = "sqladminuser"

  administrator_login_password = "Password@123456789"

}


# Azure SQL Database

resource "azurerm_mssql_database" "database" {

  name = "enterprise-database"

  server_id = azurerm_mssql_server.sql_server.id

  sku_name = "Basic"

}


# SQL Firewall Rule

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {

  name = "AllowAzureServices"

  server_id = azurerm_mssql_server.sql_server.id

  start_ip_address = "0.0.0.0"

  end_ip_address = "0.0.0.0"

}
