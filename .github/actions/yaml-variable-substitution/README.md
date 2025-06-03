# Using the YAML Variable Substitution Action

This document explains how to use the composite action for YAML variable substitution in your workflows.

## About Composite Actions

A composite action is a custom action that combines multiple steps into a single, reusable unit. Unlike reusable workflows, composite actions:

1. Run in the same job as the caller workflow
2. Can be called with `uses:` like any other action
3. Don't require their own runner
4. Can easily share context with other steps in the same job

## Using the YAML Variable Substitution Action

### Basic Usage

```yaml
- name: Process app.yaml variable substitution
  uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/actions/yaml-variable-substitution@main
  with:
    app_yaml_path: "tfvars/app.yaml"
    output_path: "tfvars/app.yaml.processed"
```

### With KeyVault Integration

```yaml
- name: Process app.yaml variable substitution
  uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/actions/yaml-variable-substitution@main
  with:
    app_yaml_path: "tfvars/app.yaml"
    output_path: "tfvars/app.yaml.processed"
    environment: "production"
    keyvault_name: "my-keyvault"
  env:
    AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
    AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
    AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Integration Example with Container App Workflow

Here's how to integrate the variable substitution action with your container app deployment workflow:

```yaml
name: Build and Deploy Container App

on:
  push:
    branches: [main]
    paths:
      - "src/**"
      - "tfvars/app.yaml"
  workflow_dispatch:

env:
  CONTAINER_APP_NAME: sample-app
  ENVIRONMENT: production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # Process app.yaml with variable substitution
      - name: Process app.yaml variable substitution
        uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/actions/yaml-variable-substitution@main
        with:
          app_yaml_path: "tfvars/app.yaml"
          output_path: "tfvars/app.yaml.processed"
          environment: ${{ env.ENVIRONMENT }}
          keyvault_name: ${{ vars.KEYVAULT_NAME }}
        env:
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      # Move processed file to original location
      - name: Use processed app.yaml
        run: |
          if [ -f "tfvars/app.yaml.processed" ]; then
            mv tfvars/app.yaml.processed tfvars/app.yaml
          fi

      # Continue with Terraform deployment
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.9.0

      # ... rest of your workflow
```

## Input Parameters

| Parameter       | Required | Default | Description                                        |
| --------------- | -------- | ------- | -------------------------------------------------- |
| `app_yaml_path` | Yes      |         | Path to the YAML file to process                   |
| `output_path`   | Yes      |         | Path where the processed YAML file will be written |
| `environment`   | No       | `dev`   | The target environment name                        |
| `keyvault_name` | No       |         | Azure KeyVault name for `kv:` substitutions        |

## Environment Variables

When using KeyVault integration, you need to provide the following environment variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## Benefits Over Reusable Workflow

Compared to the reusable workflow approach, this composite action provides:

1. **Simplified Integration**: No need for separate jobs or file copying between jobs
2. **Same Runner Context**: Runs in the same job as the rest of your workflow
3. **Better File Handling**: Direct access to files in the workflow's workspace
4. **More Intuitive**: Follows the standard pattern for GitHub Actions
5. **Easier to Maintain**: One file instead of a whole workflow structure

## Publishing as a GitHub Action

If you want to make this action available to other projects, you can:

1. Create a dedicated repository for this action
2. Publish it to the GitHub Marketplace
3. Version it with tags like `v1`, `v1.0.0`, etc.
