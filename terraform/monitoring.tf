# Log Analytics Workspace

resource "azurerm_log_analytics_workspace" "logs" {

  name = "azure3tier-log-workspace"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name

  sku = "PerGB2018"

  retention_in_days = 30

}


# Application Insights

resource "azurerm_application_insights" "appinsights" {

  name = "azure3tier-app-insights"

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name

  workspace_id = azurerm_log_analytics_workspace.logs.id

  application_type = "web"

}
