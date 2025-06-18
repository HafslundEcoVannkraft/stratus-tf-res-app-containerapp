module "containerapp" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.6.0"

  # Required parameters
  name                                  = local.app_config.name
  resource_group_name                   = local.container_apps_rg_name       # Sourced from remote state
  container_app_environment_resource_id = local.container_app_environment_id # Sourced from remote state
  revision_mode                         = local.app_config.revision_mode

  # Template configuration with comprehensive support for all properties
  template = {
    # Basic template properties
    max_replicas    = try(local.app_config.template.max_replicas, 10)
    min_replicas    = try(local.app_config.template.min_replicas, 1)
    revision_suffix = try(local.app_config.template.revision_suffix, null)

    # Container configuration - support all properties from YAML
    containers = [
      for container in try(local.app_config.template.containers, [{}]) : {
        name = try(container.name, local.app_config.name)
        # Image resolution priority:
        # 1. Image specified in YAML (for pre-built images)
        # 2. Image from container_images map (for workflow-built images)
        # 3. Image from previous state (for destroy operations)
        image = coalesce(
          try(container.image, null),                                                                                                # Priority 1: YAML-specified image
          try(lookup(var.container_images, try(container.name, local.app_config.name), null), null),                                 # Priority 2: From container_images map
          try(lookup(data.terraform_remote_state.self.outputs.container_images, try(container.name, local.app_config.name), ""), "") # Priority 3: From previous state
        )
        memory  = try(container.memory, "0.5Gi")
        cpu     = try(container.cpu, "0.25")
        args    = try(container.args, null)
        command = try(container.command, null)

        # Environment variables
        env = try(container.env, null)

        # Health probes - convert from YAML structure to module structure
        liveness_probes = try([
          for probe in container.liveness_probes : {
            transport               = probe.transport
            port                    = probe.port
            path                    = try(probe.path, null)
            host                    = try(probe.host, null)
            initial_delay           = try(probe.initial_delay, null)
            interval_seconds        = try(probe.interval_seconds, null)
            timeout                 = try(probe.timeout, null)
            failure_count_threshold = try(probe.failure_count_threshold, null)
            header                  = try(probe.header, null)
          }
        ], null)

        readiness_probes = try([
          for probe in container.readiness_probes : {
            transport               = probe.transport
            port                    = probe.port
            path                    = try(probe.path, null)
            host                    = try(probe.host, null)
            initial_delay           = try(probe.initial_delay, null)
            interval_seconds        = try(probe.interval_seconds, null)
            timeout                 = try(probe.timeout, null)
            failure_count_threshold = try(probe.failure_count_threshold, null)
            success_count_threshold = try(probe.success_count_threshold, null)
            header                  = try(probe.header, null)
          }
        ], null)

        startup_probe = try([
          for probe in container.startup_probe : {
            transport               = probe.transport
            port                    = probe.port
            path                    = try(probe.path, null)
            host                    = try(probe.host, null)
            initial_delay           = try(probe.initial_delay, null)
            interval_seconds        = try(probe.interval_seconds, null)
            timeout                 = try(probe.timeout, null)
            failure_count_threshold = try(probe.failure_count_threshold, null)
            header                  = try(probe.header, null)
          }
        ], null)

        # Volume mounts
        volume_mounts = try(container.volume_mounts, null)
      }
    ]

    # Init containers support
    init_containers = try(local.app_config.template.init_containers, null)

    # Volume configuration
    volumes = try(local.app_config.template.volumes, null)

    # Scale rules
    azure_queue_scale_rules = try(local.app_config.template.azure_queue_scale_rules, null)
    http_scale_rules        = try(local.app_config.template.http_scale_rules, null)
    tcp_scale_rules         = try(local.app_config.template.tcp_scale_rules, null)
    custom_scale_rules      = try(local.app_config.template.custom_scale_rules, null)
  }

  # Managed identities - combine system-assigned with user-assigned from YAML
  managed_identities = {
    system_assigned = try(local.app_config.managed_identities.system_assigned, true)
    user_assigned_resource_ids = concat(
      [module.container_app_identity_for_registry.resource_id],
      try(local.app_config.managed_identities.user_assigned_resource_ids, [])
    )
  }

  # Registry configuration
  registries = concat(
    [
      {
        server   = "${local.container_registry_name}.azurecr.io"
        identity = module.container_app_identity_for_registry.resource_id
      }
    ],
    try(local.app_config.registries, [])
  )

  # Ingress configuration with full support for all properties
  ingress = {
    allow_insecure_connections = try(local.app_config.ingress.allow_insecure_connections, false)
    client_certificate_mode    = try(local.app_config.ingress.client_certificate_mode, "ignore")
    target_port                = try(local.app_config.ingress.target_port, 80)
    exposed_port               = try(local.app_config.ingress.exposed_port, null)
    external_enabled           = try(local.app_config.ingress.external_enabled, true)
    transport                  = try(local.app_config.ingress.transport, "auto")

    # IP security restrictions
    ip_security_restriction = try(local.app_config.ingress.ip_security_restriction, null)

    # Traffic weight configuration
    traffic_weight = try(local.app_config.ingress.traffic_weight, [{
      label           = "latest-100"
      latest_revision = true
      percentage      = 100
    }])
  }

  # Dapr configuration
  dapr = can(local.app_config.dapr) ? {
    app_id       = try(local.app_config.dapr.app_id, local.app_config.name)
    app_port     = try(local.app_config.dapr.app_port, null)
    app_protocol = try(local.app_config.dapr.app_protocol, "http")
  } : null

  # Custom domains configuration
  custom_domains = try(local.app_config.custom_domains, {})

  # Secrets configuration - support for Key Vault references and direct values
  secrets = try(local.app_config.secrets, {})

  # Authentication configurations
  auth_configs = try(local.app_config.auth_configs, {})

  # Resource locks
  lock = try(local.app_config.lock, null)

  # Role assignments
  role_assignments = try(local.app_config.role_assignments, {})

  # Timeouts for container app operations
  container_app_timeouts = try(local.app_config.container_app_timeouts, {
    create = "30m"
    update = "30m"
    read   = "5m"
    delete = "30m"
  })

  # Workload profile name
  workload_profile_name = try(local.app_config.workload_profile_name, "Consumption")

  # Tags for the container app
  tags = try(local.app_config.tags, null)

  # This is about Telemetry for Microsoft Azure Verified Module usage, not application telemetry
  # https://registry.terraform.io/providers/Azure/avm/latest/docs#enable_telemetry
  enable_telemetry = try(local.app_config.enable_telemetry, true)

  depends_on = [
  ]
}

# Optional: Add validation using check blocks (requires Terraform 1.5+)
# Uncomment if you want explicit validation
# check "container_images_provided" {
#   assert {
#     condition = alltrue([
#       for container in try(local.app_config.template.containers, []) :
#       can(container.image) || can(lookup(var.container_images, try(container.name, local.app_config.name), null))
#     ])
#     error_message = "All containers must have an image specified either in YAML or via container_images variable."
#   }
# }
