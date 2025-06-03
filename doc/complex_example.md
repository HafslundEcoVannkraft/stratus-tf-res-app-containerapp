# Azure Container App Example

This example demonstrates deploying a web application with:

- External ingress with custom domain
- AAD authentication
- Dapr component integration
- Multiple replicas and scaling
- Health checks for reliability
- Resource allocation and limits

## YAML Configuration

```yaml
name: "web-app"
revision_mode: "Multiple"
container_app_environment_target: "production" # Target the production environment in the remote state

# Note: resource_group_name and container_app_environment_resource_id are now
# automatically sourced from remote state

template:
  max_replicas: 10
  min_replicas: 2
  revision_suffix: "v1"

  containers:
    - name: "web-app"
      # image: "myregistry.azurecr.io/web-app:v2.1" # Uncomment to override the image built by GitHub workflow
      cpu: 0.5
      memory: "1Gi"
      env:
        - name: "ENVIRONMENT"
          value: "${vars:ENVIRONMENT:production}"
        - name: "APPLICATIONINSIGHTS_CONNECTION_STRING"
          value: "${kv:applicationinsights-connection-string}"
        - name: "DB_CONNECTION_STRING"
          value: "${secrets:db_connection_string!}" # Required secret
        - name: "DEBUG_MODE"
          value: "${env:DEBUG_MODE:false}" # Can be overridden at runtime

      liveness_probes:
        - transport: "HTTP"
          port: 8080
          path: "/health"
          interval_seconds: 10
          timeout: 5
          failure_count_threshold: 3

      readiness_probes:
        - transport: "HTTP"
          port: 8080
          path: "/ready"
          interval_seconds: 10

  http_scale_rules:
    - name: "http-scale"
      concurrent_requests: "50"

ingress:
  external_enabled: true
  target_port: 8080
  transport: "http"
  client_certificate_mode: "ignore"

  traffic_weight:
    - label: "production"
      latest_revision: true
      percentage: 100

  ip_security_restriction:
    - name: "allow-corporate"
      action: "Allow"
      ip_address_range: "10.0.0.0/8"
      description: "Allow corporate network"

dapr:
  app_id: "web-app"
  app_port: 8080
  app_protocol: "http"

custom_domains:
  domain1:
    name: "app.example.com"
    certificate_binding_type: "SniEnabled"
    container_app_environment_certificate_id: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.App/managedEnvironments/{env_name}/certificates/{cert_name}"

auth_configs:
  auth-config-1:
    name: "aad-auth"
    platform:
      enabled: true
      runtime_version: "v2"
    global_validation:
      unauthenticated_client_action: "RedirectToLoginPage"
      exclude_paths:
        - "/api/health"
        - "/metrics"
    identity_providers:
      azure_active_directory:
        enabled: true
        registration:
          client_id: "${aad_client_id}"
          client_secret_setting_name: "AAD_CLIENT_SECRET"
          open_id_issuer: "https://login.microsoftonline.com/v2.0/${tenant_id}/"

secrets:
  aad-secret:
    name: "AAD_CLIENT_SECRET"
    value: "${aad_client_secret}"
  api-key:
    name: "API_KEY"
    key_vault_secret_id: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.KeyVault/vaults/{vault_name}/secrets/apiKey"
    identity: "System"

managed_identities:
  system_assigned: true
  user_assigned_resource_ids:
    - "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity_name}"

workload_profile_name: "Consumption"

tags:
  Environment: "Production"
  Department: "IT"
  Application: "WebApp"
```

## Terraform Module Usage

```hcl
module "web_app" {
  source = "github.com/HafslundEcoVannkraft/stratus-tf-res-app-containerapp"

  subscription_id            = "00000000-0000-0000-0000-000000000000"
  location                   = "northeurope"
  code_name                  = "myteam"
  environment                = "prod"
  state_storage_account_name = "stratusstate"

  # Remote state configuration for Container App Environment
  remote_tfstate_rg            = "rg-tfstate"
  remote_tfstate_storage_account = "stratustfstate"
  remote_tfstate_container     = "tfstate"
  remote_tfstate_key           = "env/container-apps.tfstate"

  # Container image details
  image_name                  = "myregistry.azurecr.io/web-app"
  image_tag                   = "v1.2.3"

  # Optional: Override the default App Gateway DNS name
  appgw_dns_name              = "appgw.example.com"
}
```

## Implementation Notes

1. The YAML file must be placed in `tfvars/app.yaml` relative to the module directory
2. Sensitive values can be passed directly in the YAML but consider using Key Vault references for production
3. The Container App Environment must be deployed first and referenced via remote state
