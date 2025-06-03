module "containerapp" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.6.0"

  name                                  = local.app_config.name
  resource_group_name                   = local.container_apps_rg_name
  container_app_environment_resource_id = local.container_app_environment_id
  revision_mode                         = local.app_config.revision_mode


  template = {
    max_replicas = try(local.app_config.template.max_replicas, 10)
    min_replicas = try(local.app_config.template.min_replicas, 1)
    command      = try(local.app_config.template.command, null)
    args         = try(local.app_config.template.args, null)
    env          = can(local.app_config.template.env) ? local.app_config.template.env : []

    containers = [
      {
        name   = local.app_config.name
        memory = try(local.app_config.template.containers[0].memory, "0.5Gi")
        cpu    = try(local.app_config.template.containers[0].cpu, "0.25")
        image  = try("${local.app_config.template.image_name}:${local.app_config.template.image_tag}", "${var.image_name}:${var.image_tag}")
      }
    ]
    http_scale_rules = can(local.app_config.template.http_scale_rules) ? local.app_config.template.http_scale_rules : []
  }

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [module.container_app_identity_for_registry.resource_id]
  }

  registries = [
    {
      server   = "${local.container_registry_name}.azurecr.io"
      identity = module.container_app_identity_for_registry.resource_id
    }
  ]

  ingress = {
    allow_insecure_connections = try(local.app_config.ingress.allow_insecure_connections, false)
    client_certificate_mode    = try(local.app_config.ingress.client_certificate_mode, "ignore")
    target_port                = try(local.app_config.ingress.target_port, 80)
    external_enabled           = try(local.app_config.ingress.external_enabled, true)

    traffic_weight = [can(local.app_config.ingress.traffic_weight) ? {
      label           = local.app_config.ingress.traffic_weight[0].label
      latest_revision = local.app_config.ingress.traffic_weight[0].latest_revision
      percentage      = local.app_config.ingress.traffic_weight[0].percentage
      } : {
      label           = "latest-100"
      latest_revision = true
      percentage      = 100
    }]
  }

  dapr = can(local.app_config.dapr) ? {
    app_id       = try(local.app_config.dapr.app_id, local.app_config.name)
    app_port     = try(local.app_config.dapr.app_port, null)
    app_protocol = try(local.app_config.dapr.app_protocol, "http")
  } : null

  tags = try(local.app_config.tags, null)

  container_app_timeouts = try(local.app_config.container_app_timeouts, {
    create = "30m"
    update = "30m"
    read   = "5m"
    delete = "30m"
  })

  workload_profile_name = try(local.app_config.workload_profile_name, "Consumption")

  # This is about Telemetry for Microsoft Azure Verified Module usage, not application telemetry
  # https://registry.terraform.io/providers/Azure/avm/latest/docs#enable_telemetry
  enable_telemetry = try(local.app_config.enable_telemetry, true)
}
