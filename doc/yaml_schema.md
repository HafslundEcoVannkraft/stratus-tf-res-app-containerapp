# YAML Schema Documentation

This document provides a reference for the YAML configuration schema used by the `stratus-tf-res-app-containerapp` module. The YAML configuration is stored in a file named `app.yaml` in the `tfvars` directory.

## Schema Overview

The `app.yaml` file is used to configure all aspects of a Container App deployment, including containers, ingress, authentication, Dapr integration, secrets, and more. Below is a detailed description of all supported properties.

## Top-Level Properties

| Property                           | Type    | Required | Default                                                       | Description                                                                                                                                                                       |
| ---------------------------------- | ------- | -------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                             | string  | Yes      | -                                                             | The name of the Container App.                                                                                                                                                    |
| `revision_mode`                    | string  | Yes      | -                                                             | The revision mode for the Container App. Valid values: `Single`, `Multiple`.                                                                                                      |
| `container_app_environment_target` | string  | No       | `ace1`                                                        | Target a specific environment when multiple exist in the remote state. This identifies which container app environment to use based on the `deployment_target` metadata property in remote terraform state output. |
| `template`                         | object  | Yes      | -                                                             | Configuration for the Container App template.                                                                                                                                     |
| `managed_identities`               | object  | No       | `{ system_assigned: true }`                                   | Managed identity configuration.                                                                                                                                                   |
| `registries`                       | array   | No       | -                                                             | Additional container registries to use.                                                                                                                                           |
| `ingress`                          | object  | No       | -                                                             | Ingress configuration.                                                                                                                                                            |
| `dapr`                             | object  | No       | -                                                             | Dapr configuration.                                                                                                                                                               |
| `custom_domains`                   | object  | No       | -                                                             | Custom domains configuration.                                                                                                                                                     |
| `secrets`                          | object  | No       | -                                                             | Secrets configuration.                                                                                                                                                            |
| `auth_configs`                     | object  | No       | -                                                             | Authentication configurations.                                                                                                                                                    |
| `lock`                             | object  | No       | -                                                             | Resource locks configuration.                                                                                                                                                     |
| `role_assignments`                 | object  | No       | -                                                             | Role assignments.                                                                                                                                                                 |
| `container_app_timeouts`           | object  | No       | `{ create: "30m", update: "30m", read: "5m", delete: "30m" }` | Timeouts for container app operations.                                                                                                                                            |
| `workload_profile_name`            | string  | No       | `Consumption`                                                 | The workload profile name.                                                                                                                                                        |
| `tags`                             | object  | No       | -                                                             | Tags for the container app.                                                                                                                                                       |
| `enable_telemetry`                 | boolean | No       | `true`                                                        | Whether to enable telemetry for the Azure Verified Module.                                                                                                                        |

## Template Configuration

The `template` object configures the Container App template, including containers, scaling rules, and volumes.

| Property                  | Type   | Required | Default | Description                                       |
| ------------------------- | ------ | -------- | ------- | ------------------------------------------------- |
| `max_replicas`            | number | No       | `10`    | Maximum number of replicas.                       |
| `min_replicas`            | number | No       | `1`     | Minimum number of replicas.                       |
| `revision_suffix`         | string | No       | -       | Suffix to append to the revision name.            |
| `containers`              | array  | No       | `[{}]`  | Array of container configurations.                |
| `init_containers`         | array  | No       | -       | Array of initialization container configurations. |
| `volumes`                 | array  | No       | -       | Array of volume configurations.                   |
| `azure_queue_scale_rules` | array  | No       | -       | Azure Queue scaling rules.                        |
| `http_scale_rules`        | array  | No       | -       | HTTP scaling rules.                               |
| `tcp_scale_rules`         | array  | No       | -       | TCP scaling rules.                                |
| `custom_scale_rules`      | array  | No       | -       | Custom scaling rules.                             |

### Container Configuration

Each container in the `containers` array can have the following properties:

| Property           | Type   | Required | Default             | Description                                                                                                                             |
| ------------------ | ------ | -------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `name`             | string | No       | value of `app.name` | The name of the container.                                                                                                              |
| `image`            | string | No       | -                   | The container image to use. If not provided, the image will be sourced from the `container_images` variable or from the previous state. |
| `memory`           | string | No       | `0.5Gi`             | Memory allocation for the container (e.g., `0.5Gi`, `1Gi`).                                                                             |
| `cpu`              | string | No       | `0.25`              | CPU allocation for the container (e.g., `0.25`, `0.5`, `1`).                                                                            |
| `args`             | array  | No       | -                   | Command arguments.                                                                                                                      |
| `command`          | array  | No       | -                   | Command to run.                                                                                                                         |
| `env`              | array  | No       | -                   | Environment variables.                                                                                                                  |
| `liveness_probes`  | array  | No       | -                   | Liveness probe configuration.                                                                                                           |
| `readiness_probes` | array  | No       | -                   | Readiness probe configuration.                                                                                                          |
| `startup_probe`    | array  | No       | -                   | Startup probe configuration.                                                                                                            |
| `volume_mounts`    | array  | No       | -                   | Volume mount configuration.                                                                                                             |

### Environment Variables

Environment variables are defined as an array of objects:

| Property      | Type   | Required | Default | Description                                                                    |
| ------------- | ------ | -------- | ------- | ------------------------------------------------------------------------------ |
| `name`        | string | Yes      | -       | Name of the environment variable.                                              |
| `value`       | string | No       | -       | Value of the environment variable.                                             |
| `secret_name` | string | No       | -       | Name of the secret to use. Either `value` or `secret_name` should be provided. |

### Health Probes

Health probes (liveness, readiness, startup) have the following properties:

| Property                  | Type   | Required | Default | Description                                                      |
| ------------------------- | ------ | -------- | ------- | ---------------------------------------------------------------- |
| `transport`               | string | Yes      | -       | Transport protocol (`http`, `https`, `tcp`).                     |
| `port`                    | number | Yes      | -       | Port to probe.                                                   |
| `path`                    | string | No       | -       | Path to probe (for HTTP/HTTPS).                                  |
| `host`                    | string | No       | -       | Host header to set for the probe.                                |
| `initial_delay`           | number | No       | -       | Initial delay in seconds.                                        |
| `interval_seconds`        | number | No       | -       | Interval between probes in seconds.                              |
| `timeout`                 | number | No       | -       | Timeout for the probe in seconds.                                |
| `failure_count_threshold` | number | No       | -       | Number of failures before considering unhealthy.                 |
| `success_count_threshold` | number | No       | -       | Number of successes before considering healthy (readiness only). |
| `header`                  | object | No       | -       | Headers to set for HTTP/HTTPS probes.                            |

## Ingress Configuration

The `ingress` object configures how the Container App is exposed:

| Property                     | Type    | Required | Default                                                             | Description                                                           |
| ---------------------------- | ------- | -------- | ------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `allow_insecure_connections` | boolean | No       | `false`                                                             | Whether to allow insecure connections.                                |
| `client_certificate_mode`    | string  | No       | `ignore`                                                            | Client certificate mode. Valid values: `ignore`, `accept`, `require`. |
| `target_port`                | number  | No       | `80`                                                                | Target port for the ingress.                                          |
| `exposed_port`               | number  | No       | -                                                                   | Exposed port for the ingress.                                         |
| `external_enabled`           | boolean | No       | `true`                                                              | Whether the ingress is exposed externally.                            |
| `transport`                  | string  | No       | `auto`                                                              | Transport protocol. Valid values: `auto`, `http`, `http2`.            |
| `ip_security_restriction`    | array   | No       | -                                                                   | IP security restrictions.                                             |
| `traffic_weight`             | array   | No       | `[{ label: "latest-100", latest_revision: true, percentage: 100 }]` | Traffic weight configuration.                                         |

### Traffic Weight

Traffic weight items have the following properties:

| Property          | Type    | Required | Default | Description                                              |
| ----------------- | ------- | -------- | ------- | -------------------------------------------------------- |
| `label`           | string  | Yes      | -       | Label for the revision.                                  |
| `latest_revision` | boolean | No       | -       | Whether this is the latest revision.                     |
| `revision_suffix` | string  | No       | -       | Revision suffix or name.                                 |
| `percentage`      | number  | Yes      | -       | Percentage of traffic to route to this revision (0-100). |

## Dapr Configuration

The `dapr` object configures Dapr integration:

| Property       | Type   | Required | Default             | Description                                                               |
| -------------- | ------ | -------- | ------------------- | ------------------------------------------------------------------------- |
| `app_id`       | string | No       | value of `app.name` | Dapr application ID.                                                      |
| `app_port`     | number | No       | -                   | Port for the Dapr application.                                            |
| `app_protocol` | string | No       | `http`              | Protocol for the Dapr application. Valid values: `http`, `grpc`, `https`. |

## Managed Identities

The `managed_identities` object configures identity for the Container App:

| Property                     | Type    | Required | Default | Description                                                                                                       |
| ---------------------------- | ------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------------- |
| `system_assigned`            | boolean | No       | `true`  | Whether to enable system-assigned identity.                                                                       |
| `user_assigned_resource_ids` | array   | No       | -       | List of user-assigned identity resource IDs. Note: The module automatically adds an identity for ACR pull access. |

## Registries

The `registries` array configures additional container registries:

| Property   | Type   | Required | Default | Description                                      |
| ---------- | ------ | -------- | ------- | ------------------------------------------------ |
| `server`   | string | Yes      | -       | Registry server URL.                             |
| `identity` | string | Yes      | -       | Managed identity resource ID for authentication. |

## Custom Domains

The `custom_domains` object configures custom domains:

| Property  | Type   | Required | Default | Description                         |
| --------- | ------ | -------- | ------- | ----------------------------------- |
| `domain1` | object | No       | -       | First custom domain configuration.  |
| `domain2` | object | No       | -       | Second custom domain configuration. |
| ...       | ...    | ...      | ...     | ...                                 |

### Custom Domain Configuration

| Property               | Type   | Required | Default      | Description                                              |
| ---------------------- | ------ | -------- | ------------ | -------------------------------------------------------- |
| `certificate_name`     | string | Yes      | -            | Name of the certificate.                                 |
| `certificate_value`    | string | Yes      | -            | Value of the certificate.                                |
| `certificate_password` | string | No       | -            | Password for the certificate.                            |
| `binding_type`         | string | No       | `SniEnabled` | Type of binding. Valid values: `SniEnabled`, `Disabled`. |

## Secrets

The `secrets` object configures secrets for the Container App:

| Property      | Type   | Required | Default | Description           |
| ------------- | ------ | -------- | ------- | --------------------- |
| `secret_name` | object | No       | -       | Secret configuration. |

### Secret Configuration

| Property              | Type   | Required | Default | Description              |
| --------------------- | ------ | -------- | ------- | ------------------------ |
| `value`               | string | No       | -       | Secret value.            |
| `key_vault_reference` | string | No       | -       | Key Vault reference URL. |

## Example Configuration

```yaml
name: "sample-app"
revision_mode: "Single"
container_app_environment_target: ace1

template:
  max_replicas: 10
  min_replicas: 1
  containers:
    - name: "api"
      # image: "myregistry.azurecr.io/sample-app:v1.0"  # Uncomment to override image
      cpu: 0.5
      memory: "1Gi"
      env:
        - name: "ENVIRONMENT"
          value: "production"
        - name: "API_KEY"
          secret_name: "api-key"
      liveness_probes:
        - transport: "http"
          port: 8080
          path: "/health/liveness"
          interval_seconds: 10
          timeout: 5
      readiness_probes:
        - transport: "http"
          port: 8080
          path: "/health/readiness"
          interval_seconds: 10
          timeout: 5

ingress:
  external_enabled: true
  target_port: 8080
  traffic_weight:
    - label: "latest"
      latest_revision: true
      percentage: 100

dapr:
  app_id: "sample-app"
  app_port: 8080
  app_protocol: "http"

secrets:
  api-key:
    value: "my-api-key"

tags:
  Environment: "Production"
  Application: "Sample App"
```

## Variable Substitution

**Note**: Variable substitution is planned for a future release and is not yet implemented. Once implemented, it will support referencing values from various sources:

```yaml
env:
  - name: "DB_CONNECTION"
    value: "${kv:database-connection}" # From Azure KeyVault
  - name: "API_KEY"
    value: "${secrets:api_key!}" # Required secret from GitHub Secrets
  - name: "LOG_LEVEL"
    value: "${vars:LOG_LEVEL:INFO}" # From GitHub Variables with default
```
