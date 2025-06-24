# Stratus Wrapper Module for Azure Container App

This module is an opinionated wrapper around the [Azure Verified Module for Container Apps](https://github.com/Azure/terraform-azurerm-avm-res-app-containerapp), specifically tailored for the Stratus Azure Landing Zone architecture. It standardizes deployment patterns and provides simplified configuration for Container Apps in Stratus environments.

## Key Features

- Streamlined YAML-based configuration approach
- Built-in Dapr integration support
- Pre-configured identity and security settings aligned with Stratus best practices
- Integrated with Stratus Container App Environment module
- Support for custom domains, authentication, and scale rules

## Design Philosophy

This wrapper reduces complexity by providing sensible defaults while still exposing the full power of Azure Container Apps when needed. It's designed to work seamlessly with other Stratus modules in a Landing Zone deployment.

> **Note:** While this module is primarily designed for Stratus Azure Landing Zone, it can be adapted for other use cases with appropriate configuration.

## YAML Configuration

This module uses a YAML-driven approach to simplify configuration. Place your configuration in `tfvars/app.yaml`. See the [YAML Schema Documentation](doc/yaml_schema.md) for comprehensive details on all supported properties.

### Integration with Container App Environment

This module is designed to work seamlessly with the Stratus Container App Environment module. Key resources like the resource group and container app environment are automatically sourced from the remote state, simplifying configuration and ensuring consistency.

The following resources are automatically retrieved from the remote state:

- Resource group for container apps
- Container App Environment resource ID
- Container Registry information
- Storage Account details
- Log Analytics workspace
- Application Insights
- DNS zones
- Role assignments for system and user-assigned identities
- Global environment variables

### GitHub Workflow Integration

This module is designed to work with GitHub Actions workflows for CI/CD of container apps. By default, the module uses the `image_name` and `image_tag` variables which are passed by the GitHub workflow after building and pushing the container image.

If you need to override this behavior and use a specific image, you can set the `image` property in the container configuration:

```yaml
containers:
  - name: "my-app"
    image: "myregistry.azurecr.io/my-custom-image:v1.2.3" # This will override the image from GitHub workflow
    # other container properties...
```

This can be useful for:

- Testing with specific image versions
- Using pre-built images from other repositories
- Multi-stage deployments with different images

### Multi-Environment Support

The module supports targeting specific container app environments in a remote state when multiple environments exist. This is particularly useful in Stratus Landing Zones where you might have different different types of environments within the same state file.

To specify which environment to target configure this, defaults to ace1 who is also the default in stratus-tf-examples when creating a Azure Container App Environment

```yaml
container_app_environment_target: ace1
```

This will match against the `deployment_target` metadata property in the container apps configuration from the remote state.

### Dynamic Role Assignments

The module automatically configures role assignments based on the remote state output from the container app environment. This includes:

1. **System-Assigned Identity Roles**: Roles defined in the `SystemAssignedIdentityRoles` array in the remote state are automatically assigned to the container app's system-assigned identity.

2. **User-Assigned Identity Roles**: Roles defined in the `UserAssignedIdentityRoles` array in the remote state are automatically assigned to the container app's user-assigned identity.

This approach ensures that container apps have the appropriate permissions to interact with other Azure resources without manual configuration for each app.

### Environment Variables

Environment variables can be defined at two levels:

1. **Global Environment Variables**: Defined in the remote state's container app environment configuration as `variables`. These are automatically applied to all containers.

2. **Container-Specific Environment Variables**: Defined in the app.yaml file for each container.

The module automatically merges these two sources, with container-specific variables taking precedence in case of conflicts. This allows common configuration to be defined once at the environment level while still allowing container-specific customization.

### Example Configuration

```yaml
name: "sample-app"
revision_mode: "Single"
container_app_environment_target: ace1 # Target a specific environment when multiple exist

# Note: resource_group_name and container_app_environment_resource_id are now
# automatically sourced from remote state

template:
  max_replicas: 10
  min_replicas: 1
  containers:
    - # image: "myregistry.azurecr.io/sample-app:v1.0" # Uncomment to override the image built by GitHub workflow
      cpu: 0.5
      memory: "1Gi"
      # Container-specific environment variables (merged with global variables from remote state)
      env:
        - name: "ENVIRONMENT"
          value: "production"
        - name: "LOG_LEVEL"
          value: "INFO"
        # This would override any KEY_VAULT_URI from global variables
        - name: "API_VERSION"
          value: "v2"

ingress:
  external_enabled: true
  target_port: 8080

dapr:
  app_id: "sample-app"
  app_port: 8080
  app_protocol: "http"
```

### Variable Substitution (TODO: Planed for next release)

The YAML configuration supports variable substitution, allowing you to reference values from various sources:

```yaml
env:
  - name: "DB_CONNECTION"
    value: "${kv:database-connection}" # From Azure KeyVault
  - name: "API_KEY"
    value: "${secrets:api_key!}" # Required secret from GitHub Secrets
  - name: "LOG_LEVEL"
    value: "${vars:LOG_LEVEL:INFO}" # From GitHub Variables with default
```

Variable sources are checked in this order:

1. GitHub Repository/Environment Variables (`vars:`)
2. GitHub Repository/Environment Secrets (`secrets:`)
3. Azure KeyVault (`kv:`)
4. GitHub Runner Environment Variables (`env:`)