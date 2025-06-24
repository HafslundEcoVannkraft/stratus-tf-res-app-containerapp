# Managed Identity for the Container App Environment
module "container_app_identity_for_registry" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  name                = local.app_identity_name
  location            = var.location
  resource_group_name = local.container_apps_rg_name
  enable_telemetry    = true
}

# Default role assignment for ACR access - always needed for container apps
resource "azurerm_role_assignment" "aca_container_registry_pull" {
  scope                = local.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.container_app_identity_for_registry.principal_id
}

# Dynamic System-Assigned Identity Role Assignments from remote state
resource "azurerm_role_assignment" "system_assigned_roles" {
  for_each = {
    for idx, role_assignment in try(local.cae_config.SystemAssignedIdentityRoles, []) :
    "${role_assignment.role}-${idx}" => role_assignment
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = module.containerapp.resource.identity[0].principal_id

  # Only create after the container app is fully deployed with its system-assigned identity
  depends_on = [
    module.containerapp
  ]
}

# Dynamic User-Assigned Identity Role Assignments from remote state
# Note: This is in addition to the default AcrPull role above
resource "azurerm_role_assignment" "user_assigned_roles" {
  for_each = {
    for idx, role_assignment in try(local.cae_config.UserAssignedIdentityRoles, []) :
    # Skip the AcrPull role as it's already assigned above
    "${role_assignment.role}-${idx}" => role_assignment
    if role_assignment.role != "AcrPull"
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = module.container_app_identity_for_registry.principal_id
}
