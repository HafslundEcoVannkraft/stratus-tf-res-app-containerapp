locals {

  # Load the YAML configuration file
  app_config = yamldecode(file("${path.cwd}/tfvars/app.yaml"))

  # Resource names
  app_identity_name = "${var.code_name}-id-${local.app_config.name}-${var.environment}"

  # Target environment configuration - this identifies which container app environment to use
  # This allows targeting a specific environment when multiple environments exist in the remote state
  container_app_environment_target = try(local.app_config.container_app_environment_target, "default")

  # Extract specific config by container_app_environment_target
  # Note: container_apps_config is an array of objects where each object represents a deployment target configuration
  cae_config = [
    for config in data.terraform_remote_state.container_app_environment.outputs.container_apps_config :
    config if lookup(config.metadata, "deployment_target", "") == local.container_app_environment_target
  ][0]

  # Container Apps Environment Configuration
  container_app_environment_id   = local.cae_config.container_app_environment_id
  container_app_environment_name = local.cae_config.container_app_environment_name
  container_registry_id          = local.cae_config.container_registry_id
  container_registry_name        = local.cae_config.container_registry_name
  storage_account_id             = local.cae_config.storage_account_id
  storage_account_name           = local.cae_config.storage_account_name

  # Container Apps Deployment Configuration
  container_apps_rg_name                   = local.cae_config.container_apps_rg_name
  log_analytics_workspace_id               = local.cae_config.log_analytics_workspace_id
  log_analytics_workspace_name             = local.cae_config.log_analytics_workspace_name
  application_insights_id                  = local.cae_config.application_insights_id
  application_insights_name                = local.cae_config.application_insights_name
  application_insights_instrumentation_key = local.cae_config.application_insights_instrumentation_key
  application_insights_connection_string   = local.cae_config.application_insights_connection_string

  # DNS Zones
  private_dns_zone_id   = local.cae_config.private_dns_zone_id
  private_dns_zone_name = local.cae_config.private_dns_zone_name
  public_dns_zone_id    = local.cae_config.public_dns_zone_id
  public_dns_zone_name  = local.cae_config.public_dns_zone_name

}
