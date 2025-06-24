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

This module uses a YAML-driven approach to simplify configuration. Place your configuration in `tfvars/app.yaml`. See the [YAML Schema Documentation](doc/yaml\_schema.md) for comprehensive details on all supported properties.

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

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.20.0, < 5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 4.20.0, < 5.0)

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

## Resources

The following resources are used by this module:

- [azurerm_dns_cname_record.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) (resource)
- [azurerm_private_dns_cname_record.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_cname_record) (resource)
- [azurerm_role_assignment.aca_container_registry_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.system_assigned_roles](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.user_assigned_roles](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [terraform_remote_state.container_app_environment](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) (data source)
- [terraform_remote_state.self](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_code_name"></a> [code\_name](#input\_code\_name)

Description: The code name for the product team

Type: `string`

### <a name="input_environment"></a> [environment](#input\_environment)

Description: The environment

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: The location of the resources

Type: `string`

### <a name="input_state_storage_account_name"></a> [state\_storage\_account\_name](#input\_state\_storage\_account\_name)

Description: The name of the gitops storage account

Type: `string`

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description: The subscription ID for the Azure provider

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_container_images"></a> [container\_images](#input\_container\_images)

Description: Map of container names to fully qualified image URLs (e.g., registry.azurecr.io/app-name:tag). Used for multi-container support.

Type: `map(string)`

Default: `null`

### <a name="input_remote_tfstate_container"></a> [remote\_tfstate\_container](#input\_remote\_tfstate\_container)

Description: The name of the container for remote Terraform state

Type: `string`

Default: `"tfstate"`

### <a name="input_remote_tfstate_key"></a> [remote\_tfstate\_key](#input\_remote\_tfstate\_key)

Description: The key for the remote Terraform state file

Type: `string`

Default: `null`

### <a name="input_remote_tfstate_rg"></a> [remote\_tfstate\_rg](#input\_remote\_tfstate\_rg)

Description: The resource group name for the remote Terraform state

Type: `string`

Default: `null`

### <a name="input_remote_tfstate_storage_account"></a> [remote\_tfstate\_storage\_account](#input\_remote\_tfstate\_storage\_account)

Description: The name of the storage account for remote Terraform state

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_app_config"></a> [app\_config](#output\_app\_config)

Description: The parsed app.yaml configuration used for this deployment.

### <a name="output_container_app_environment_id"></a> [container\_app\_environment\_id](#output\_container\_app\_environment\_id)

Description: The ID of the Container App Environment where this app is deployed.

### <a name="output_container_app_identity"></a> [container\_app\_identity](#output\_container\_app\_identity)

Description: The User Assigned Managed Identity created for the Container App.

### <a name="output_container_images"></a> [container\_images](#output\_container\_images)

Description: Map of container names to their current images.

### <a name="output_containers"></a> [containers](#output\_containers)

Description: The containers configuration of the Container App, including names and images.

### <a name="output_custom_domain_verification_id"></a> [custom\_domain\_verification\_id](#output\_custom\_domain\_verification\_id)

Description: The ID to be used for domain verification.

### <a name="output_id"></a> [id](#output\_id)

Description: The ID of the Container App.

### <a name="output_identity"></a> [identity](#output\_identity)

Description: The identity block of the Container App.

### <a name="output_ingress_fqdn"></a> [ingress\_fqdn](#output\_ingress\_fqdn)

Description: The FQDN of the Container App's ingress.

### <a name="output_latest_revision_fqdn"></a> [latest\_revision\_fqdn](#output\_latest\_revision\_fqdn)

Description: The FQDN of the latest revision of the Container App.

### <a name="output_latest_revision_name"></a> [latest\_revision\_name](#output\_latest\_revision\_name)

Description: The name of the latest revision of the Container App.

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the Container App.

### <a name="output_outbound_ip_addresses"></a> [outbound\_ip\_addresses](#output\_outbound\_ip\_addresses)

Description: The outbound IP addresses of the Container App.

### <a name="output_private_dns_cname_record"></a> [private\_dns\_cname\_record](#output\_private\_dns\_cname\_record)

Description: The private DNS CNAME record created for the Container App.

### <a name="output_public_dns_cname_record"></a> [public\_dns\_cname\_record](#output\_public\_dns\_cname\_record)

Description: The public DNS CNAME record created for the Container App.

### <a name="output_template"></a> [template](#output\_template)

Description: The complete template configuration of the Container App.

## Modules

The following Modules are called:

### <a name="module_container_app_identity_for_registry"></a> [container\_app\_identity\_for\_registry](#module\_container\_app\_identity\_for\_registry)

Source: Azure/avm-res-managedidentity-userassignedidentity/azurerm

Version: 0.3.3

### <a name="module_containerapp"></a> [containerapp](#module\_containerapp)

Source: Azure/avm-res-app-containerapp/azurerm

Version: 0.6.0

<!-- END_TF_DOCS -->