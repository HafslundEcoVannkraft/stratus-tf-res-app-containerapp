<!-- BEGIN_TF_DOCS -->
# Stratus Wrapper Module for Azure Container App

This module is an opinionated wrapper around the [Azure Verified Module for Container Apps](https://github.com/Azure/terraform-azurerm-avm-res-app-containerapp), specifically tailored for the Stratus Azure Landing Zone architecture. It standardizes deployment patterns and provides simplified configuration for Container Apps in Stratus environments.

## Key Features

- Streamlined YAML-based configuration approach
- Built-in Dapr integration support
- Pre-configured identity and security settings aligned with Stratus best practices
- Integrated with Stratus Container App Environment module

## Design Philosophy

This wrapper reduces complexity by providing sensible defaults while still exposing the full power of Azure Container Apps when needed. It's designed to work seamlessly with other Stratus modules in a Landing Zone deployment.

> **Note:** While this module is primarily designed for Stratus Azure Landing Zone, it can be adapted for other use cases with appropriate configuration.

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

- [azurerm_role_assignment.aca_container_registry_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.aca_storage_blob_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [terraform_remote_state.container_app_environment](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_code_name"></a> [code\_name](#input\_code\_name)

Description: The code name for the product team

Type: `string`

### <a name="input_environment"></a> [environment](#input\_environment)

Description: The environment

Type: `string`

### <a name="input_image_name"></a> [image\_name](#input\_image\_name)

Description: The name of the container image to deploy

Type: `string`

### <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag)

Description: The tag of the container image to deploy

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

No outputs.

## Modules

The following Modules are called:

### <a name="module_container_app_identity_for_registry"></a> [container\_app\_identity\_for\_registry](#module\_container\_app\_identity\_for\_registry)

Source: Azure/avm-res-managedidentity-userassignedidentity/azurerm

Version: 0.3.3

### <a name="module_containerapp"></a> [containerapp](#module\_containerapp)

Source: Azure/avm-res-app-containerapp/azurerm

Version: 0.6.0

<!-- END_TF_DOCS -->