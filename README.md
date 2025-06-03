<!-- BEGIN_TF_DOCS -->

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

### Variable Substitution

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

For detailed information on variable substitution syntax and features, see the [YAML Schema Documentation](doc/yaml_schema.md#variable-substitution) and [Variable Substitution Examples](doc/variable_substitution.md).

### Multi-Environment Support

The module supports targeting specific container app environments in a remote state when multiple environments exist. This is particularly useful in Stratus Landing Zones where you might have different environments (dev, test, prod) or different types of environments within the same state file.

To specify which environment to target, use the `container_app_environment_target` property in your YAML configuration:

```yaml
# Target a specific environment in the remote state
container_app_environment_target: "production"
```

This will match against the `deployment_target` metadata property in the container apps configuration from the remote state.

### Sample Configuration

A complete sample configuration file is available at [doc/sample_app.yaml](doc/sample_app.yaml). You can use this as a starting point for your own configuration.

### Example Configuration

```yaml
name: "sample-app"
revision_mode: "Single"
container_app_environment_target: "default" # Target a specific environment when multiple exist

# Note: resource_group_name and container_app_environment_resource_id are now
# automatically sourced from remote state

template:
  max_replicas: 10
  min_replicas: 1
  containers:
    - # image: "myregistry.azurecr.io/sample-app:v1.0" # Uncomment to override the image built by GitHub workflow
      cpu: 0.5
      memory: "1Gi"
      env:
        - name: "ENVIRONMENT"
          value: "production"

ingress:
  external_enabled: true
  target_port: 8080

dapr:
  app_id: "sample-app"
  app_port: 8080
  app_protocol: "http"
```

## Examples

- [Simple Container App](doc/simple_example.md) - Basic configuration with external ingress
- [Complex Container App](doc/complex_example.md) - Advanced configuration with authentication, custom domains, and scaling rules
- [Variable Substitution](doc/variable_substitution.md) - Examples of using variables and secrets in your configuration

<!-- markdownlint-disable MD033 -->

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement_azurerm) (>= 4.20.0, < 5.0)

- <a name="requirement_random"></a> [random](#requirement_random) (>= 3.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider_azurerm) (>= 4.20.0, < 5.0)

- <a name="provider_terraform"></a> [terraform](#provider_terraform)

## Resources

The following resources are used by this module:

- [azurerm_role_assignment.aca_container_registry_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.aca_storage_blob_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [terraform_remote_state.container_app_environment](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) (data source)

<!-- markdownlint-disable MD013 -->

## Required Inputs

The following input variables are required:

### <a name="input_code_name"></a> [code_name](#input_code_name)

Description: The code name for the product team

Type: `string`

### <a name="input_environment"></a> [environment](#input_environment)

Description: The environment

Type: `string`

### <a name="input_image_name"></a> [image_name](#input_image_name)

Description: The name of the container image to deploy

Type: `string`

### <a name="input_image_tag"></a> [image_tag](#input_image_tag)

Description: The tag of the container image to deploy

Type: `string`

### <a name="input_location"></a> [location](#input_location)

Description: The location of the resources

Type: `string`

### <a name="input_state_storage_account_name"></a> [state_storage_account_name](#input_state_storage_account_name)

Description: The name of the gitops storage account

Type: `string`

### <a name="input_subscription_id"></a> [subscription_id](#input_subscription_id)

Description: The subscription ID for the Azure provider

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_remote_tfstate_container"></a> [remote_tfstate_container](#input_remote_tfstate_container)

Description: The name of the container for remote Terraform state

Type: `string`

Default: `"tfstate"`

### <a name="input_remote_tfstate_key"></a> [remote_tfstate_key](#input_remote_tfstate_key)

Description: The key for the remote Terraform state file

Type: `string`

Default: `null`

### <a name="input_remote_tfstate_rg"></a> [remote_tfstate_rg](#input_remote_tfstate_rg)

Description: The resource group name for the remote Terraform state

Type: `string`

Default: `null`

### <a name="input_remote_tfstate_storage_account"></a> [remote_tfstate_storage_account](#input_remote_tfstate_storage_account)

Description: The name of the storage account for remote Terraform state

Type: `string`

Default: `null`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_container_app_identity_for_registry"></a> [container_app_identity_for_registry](#module_container_app_identity_for_registry)

Source: Azure/avm-res-managedidentity-userassignedidentity/azurerm

Version: 0.3.3

### <a name="module_containerapp"></a> [containerapp](#module_containerapp)

Source: Azure/avm-res-app-containerapp/azurerm

Version: 0.6.0

<!-- END_TF_DOCS -->
