# Azure Container App YAML Schema Documentation

This document describes the YAML configuration schema used by the Stratus Terraform Wrapper Module for Azure Container Apps. The YAML file defines all aspects of your Container App deployment.

## Basic Structure

```yaml
# Required parameters
name: "your-container-app"
revision_mode: "Single" # Possible values: Single, Multiple

# Optional Stratus-specific configuration
container_app_environment_target: "production" # Target a specific environment in the remote state when multiple exist

# All other sections are optional but recommended based on your needs
```

> **Note:** The `resource_group_name` and `container_app_environment_resource_id` are now automatically sourced from the remote state and should not be specified in the YAML configuration.

## Complete Schema Reference

### Root Level Properties

| Property                                | Type    | Required | Description                                                                                                                     |
| --------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `name`                                  | string  | Yes      | The name of the container app                                                                                                   |
| `revision_mode`                         | string  | Yes      | The revision mode for the container app. Possible values: `Single`, `Multiple`                                                  |
| `resource_group_name`                   | string  | No       | **[Deprecated]** Now automatically sourced from remote state. This value will be ignored if specified.                          |
| `container_app_environment_resource_id` | string  | No       | **[Deprecated]** Now automatically sourced from remote state. This value will be ignored if specified.                          |
| `container_app_environment_target`      | string  | No       | Specifies which container app environment to target in the remote state when multiple environments exist. Defaults to "default" |
| `template`                              | object  | No       | Configuration for the container app template                                                                                    |
| `ingress`                               | object  | No       | Ingress configuration for the container app                                                                                     |
| `dapr`                                  | object  | No       | Dapr configuration for the container app                                                                                        |
| `registries`                            | array   | No       | Container registry configuration                                                                                                |
| `secrets`                               | object  | No       | Secret configuration                                                                                                            |
| `custom_domains`                        | object  | No       | Custom domain configuration                                                                                                     |
| `managed_identities`                    | object  | No       | Managed identity configuration                                                                                                  |
| `role_assignments`                      | object  | No       | Role assignment configuration                                                                                                   |
| `lock`                                  | object  | No       | Resource lock configuration                                                                                                     |
| `container_app_timeouts`                | object  | No       | Timeout configuration                                                                                                           |
| `workload_profile_name`                 | string  | No       | The name of the workload profile                                                                                                |
| `tags`                                  | object  | No       | Tags to apply to the container app                                                                                              |
| `enable_telemetry`                      | boolean | No       | Whether to enable telemetry for the AVM module                                                                                  |

### Template Configuration

```yaml
template:
  max_replicas: 10
  min_replicas: 1
  revision_suffix: "v1" # Optional

  # Container configuration (required)
  containers:
    - name: "container-name" # Optional, defaults to app name
      image: "image-name:tag" # Optional - if provided, overrides image_name and image_tag vars from GitHub workflow
      cpu: 0.25 # CPU cores
      memory: "0.5Gi" # Memory allocation
      args:
        - "--verbose"
      command:
        - "/bin/sh"
        - "-c"
        - "echo hello"
      env:
        - name: "ENV_VAR"
          value: "value"
        - name: "SECRET_ENV"
          secret_name: "my-secret"

      # Health probes
      liveness_probes:
        - transport: "HTTP" # Possible values: TCP, HTTP, HTTPS
          port: 8080
          path: "/health"
          host: "localhost"
          initial_delay: 10
          interval_seconds: 10
          timeout: 5
          failure_count_threshold: 3
          header:
            - name: "Custom-Header"
              value: "Value"

      readiness_probes:
        - transport: "HTTP"
          port: 8080
          path: "/ready"

      startup_probe:
        - transport: "HTTP"
          port: 8080
          path: "/startup"

      volume_mounts:
        - name: "config-volume"
          path: "/config"

  # Init containers
  init_containers:
    - name: "init-container"
      image: "busybox:latest"
      command:
        - "/bin/sh"
        - "-c"
        - "echo initializing app"

  # Volumes
  volumes:
    - name: "config-volume"
      storage_type: "EmptyDir" # Possible values: AzureFile, EmptyDir, Secret

  # Scale rules
  azure_queue_scale_rules:
    - name: "queue-scaler"
      queue_name: "messages"
      queue_length: 10
      authentication:
        - secret_name: "queue-connection"
          trigger_parameter: "connection"

  http_scale_rules:
    - name: "http-scaler"
      concurrent_requests: "50"
      authentication:
        - secret_name: "auth-secret"
          trigger_parameter: "auth-param"

  tcp_scale_rules:
    - name: "tcp-scaler"
      concurrent_requests: "100"

  custom_scale_rules:
    - name: "custom-scaler"
      custom_rule_type: "cpu"
      metadata:
        value: "50"
        operator: "GreaterThan"
```

### Ingress Configuration

```yaml
ingress:
  external_enabled: true
  target_port: 8080
  exposed_port: 80
  transport: "http" # Possible values: auto, http, http2, tcp
  allow_insecure_connections: false
  client_certificate_mode: "ignore" # Possible values: require, accept, ignore

  # Traffic weight distribution
  traffic_weight:
    - label: "production"
      latest_revision: true
      percentage: 90
    - label: "staging"
      revision_suffix: "v2"
      percentage: 10

  # IP security restrictions
  ip_security_restriction:
    - name: "allow-office"
      action: "Allow"
      ip_address_range: "203.0.113.0/24"
      description: "Allow office network"
```

### Dapr Configuration

```yaml
dapr:
  app_id: "my-dapr-app"
  app_port: 8080
  app_protocol: "http" # Possible values: http, grpc
```

### Container Registry Configuration

```yaml
registries:
  - server: "myregistry.azurecr.io"
    username: "registry-user"
    password_secret_name: "registry-password"
  - server: "mcr.microsoft.com"
    identity: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity_name}"
```

### Secrets Configuration

```yaml
secrets:
  my-secret:
    name: "my-secret"
    value: "super-secret-value" # Sensitive value
  keyvault-secret:
    name: "keyvault-secret"
    key_vault_secret_id: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.KeyVault/vaults/{vault_name}/secrets/{secret_name}"
    identity: "System"
```

### Custom Domains Configuration

```yaml
custom_domains:
  domain1:
    name: "app.example.com"
    certificate_binding_type: "SniEnabled" # Possible values: Disabled, SniEnabled
    container_app_environment_certificate_id: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.App/managedEnvironments/{env_name}/certificates/{cert_name}"
    timeouts:
      create: "30m"
      delete: "30m"
      read: "5m"
```

### Managed Identities Configuration

```yaml
managed_identities:
  system_assigned: true
  user_assigned_resource_ids:
    - "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity_name}"
```

### Role Assignments

```yaml
role_assignments:
  role1:
    role_definition_id_or_name: "Storage Blob Data Contributor"
    principal_id: "00000000-0000-0000-0000-000000000000"
    description: "Allow container app to access blob storage"
  role2:
    role_definition_id_or_name: "AcrPull"
    principal_id: "11111111-1111-1111-1111-111111111111"
    principal_type: "ServicePrincipal"
```

### Resource Lock

```yaml
lock:
  kind: "CanNotDelete" # Possible values: CanNotDelete, ReadOnly
  name: "lock-container-app"
```

### Timeouts

```yaml
container_app_timeouts:
  create: "30m"
  update: "30m"
  read: "5m"
  delete: "30m"
```

### Authentication Configuration

```yaml
auth_configs:
  auth-config-1:
    name: "my-auth-config"

    platform:
      enabled: true
      runtime_version: "v2"

    global_validation:
      unauthenticated_client_action: "RedirectToLoginPage" # Possible values: AllowAnonymous, RedirectToLoginPage, Return401, Return403
      redirect_to_provider: "aad"
      exclude_paths:
        - "/api/health"
        - "/metrics"

    identity_providers:
      azure_active_directory:
        enabled: true
        registration:
          client_id: "00000000-0000-0000-0000-000000000000"
          client_secret_setting_name: "AAD_CLIENT_SECRET"
          open_id_issuer: "https://login.microsoftonline.com/v2.0/{tenant-guid}/"

    login:
      routes:
        logout_endpoint: "/logout"
      token_store:
        enabled: true
      preserve_url_fragments_for_logins: true

    http_settings:
      require_https: true
```

## Example Usage

Here's a minimal example to get started:

```yaml
name: "my-app"
resource_group_name: "rg-container-apps"
container_app_environment_resource_id: "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.App/managedEnvironments/{environment_name}"
revision_mode: "Single"

template:
  containers:
    - cpu: 0.25
      memory: "0.5Gi"
      env:
        - name: "ENVIRONMENT"
          value: "production"

ingress:
  external_enabled: true
  target_port: 8080

dapr:
  app_id: "my-app"
  app_port: 8080

tags:
  Environment: "Production"
  Department: "Engineering"
```

For more complex configuration options, refer to the complete schema sections above.

## Variable Substitution

The YAML configuration supports variable substitution using the `${variable_name}` syntax. During deployment via GitHub Actions workflows, these placeholders are automatically replaced with actual values from various sources.

### Substitution Syntax

There are two forms of variable substitution:

1. **Simple substitution**: `${variable_name}`
   The system will check different sources to find a value, in priority order.

2. **Source-specific substitution**: `${source:variable_name}`
   Explicitly specify which source to use for the variable.

Examples:

```yaml
env:
  - name: "DATABASE_URL"
    value: "${database_url}" # Simple substitution
  - name: "API_KEY"
    value: "${secrets:api_key}" # Get from GitHub Secrets
  - name: "LOG_LEVEL"
    value: "${vars:log_level:INFO}" # With default value "INFO"
  - name: "REQUIRED_VALUE"
    value: "${kv:required_secret!}" # Required value (will fail if missing)
  - name: "CONNECTION_STRING"
    value: "${env:CONNECTION_STRING}" # From runner environment variables
```

### Variable Sources

When using the source-specific syntax, the following prefixes are supported:

| Prefix     | Source             | Description                                              |
| ---------- | ------------------ | -------------------------------------------------------- |
| `vars:`    | GitHub Variables   | Repository or environment variables configured in GitHub |
| `secrets:` | GitHub Secrets     | Repository or environment secrets configured in GitHub   |
| `kv:`      | Azure KeyVault     | Secrets stored in the default IaC Azure KeyVault         |
| `env:`     | Runner Environment | Environment variables available to the GitHub runner     |

### Resolution Order

When using simple substitution without a source prefix, the system will check sources in the following order:

1. GitHub Repository/Environment Variables (`vars:`)
2. GitHub Repository/Environment Secrets (`secrets:`)
3. Azure KeyVault (`kv:`)
4. GitHub Runner Environment Variables (`env:`)

This order ensures proper precedence while providing flexibility to override values at runtime if needed.

### Special Syntax Features

1. **Default Values**: You can specify default values for variables using a colon:

   ```
   ${source:variable_name:default_value}
   ```

2. **Required Variables**: Add an exclamation mark to indicate a variable is required:
   ```
   ${source:variable_name!}
   ```
   The deployment will fail if a required variable cannot be found.

### Common Use Cases

1. **Environment-specific configuration**:

   ```yaml
   env:
     - name: "ENVIRONMENT"
       value: "${vars:ENVIRONMENT:development}"
   ```

2. **Connection strings and secrets**:

   ```yaml
   env:
     - name: "APPLICATIONINSIGHTS_CONNECTION_STRING"
       value: "${kv:applicationinsights-connection-string}"
     - name: "DB_PASSWORD"
       value: "${secrets:database-password!}"
   ```

3. **Override at runtime**:
   ```yaml
   env:
     - name: "DEBUG_MODE"
       value: "${env:DEBUG_MODE:false}"
   ```
