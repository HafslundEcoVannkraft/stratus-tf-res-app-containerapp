# Managed Identity for the Container App Environment
module "container_app_identity_for_registry" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  name                = local.app_identity_name
  location            = var.location
  resource_group_name = local.container_apps_rg_name
  enable_telemetry    = true
}

# Role assignement keyvault certificate user permission assigned to the managed identity for the environment
resource "azurerm_role_assignment" "aca_container_registry_pull" {
  scope                = local.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.container_app_identity_for_registry.principal_id
}


# We can use the System assigned managed identity for the container app, role assignments

resource "azurerm_role_assignment" "aca_storage_blob_data_contributor" {
  scope                = local.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.containerapp.resource.identity[0].principal_id
}

# Enable this if the App need table or queue storage access, table and queue is not configured as dapr services
# resource "azurerm_role_assignment" "aca_storage_table_data_contributor" {
#   scope                = local.storage_account_id
#   role_definition_name = "Storage Table Data Contributor"
#   principal_id         = module.containerapp.resource.identity[0].principal_id
# }

# resource "azurerm_role_assignment" "aca_storage_queue_data_contributor" {
#   scope                = local.storage_account_id
#   role_definition_name = "Storage Queue Data Contributor"
#   principal_id         = module.containerapp.resource.identity[0].principal_id
# }
