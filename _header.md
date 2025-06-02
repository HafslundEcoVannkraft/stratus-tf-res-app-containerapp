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