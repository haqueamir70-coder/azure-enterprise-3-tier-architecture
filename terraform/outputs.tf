output "resource_group_name" {

  description = "Azure Resource Group Name"

  value = azurerm_resource_group.main.name

}


output "location" {

  description = "Azure deployment region"

  value = azurerm_resource_group.main.location

}
