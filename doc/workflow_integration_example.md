# Using Variable Substitution with Example GitHub Workflows

This document shows how to integrate the variable substitution system with your existing GitHub Actions workflows.

## Integration with Example Workflow

Here's how to integrate the substitution process with your existing example workflow:

```yaml
name: Build and Deploy Container App

on:
  push:
    branches: [main]
    paths:
      - "src/**"
      - "tfvars/app.yaml"
      - ".github/workflows/deploy-container-app.yml"
  pull_request:
    branches: [main]
    paths:
      - "src/**"
      - "tfvars/app.yaml"
  workflow_dispatch:

env:
  CONTAINER_APP_NAME: sample-app
  ENVIRONMENT: production

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Login to Azure
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Login to Azure Container Registry
        uses: azure/docker-login@v1
        with:
          login-server: ${{ secrets.ACR_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}

      - name: Build and push container image
        run: |
          IMAGE_NAME=${{ secrets.ACR_SERVER }}/${{ env.CONTAINER_APP_NAME }}
          IMAGE_TAG=$(git rev-parse --short HEAD)

          # Build and push Docker image
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ./src
          docker push ${IMAGE_NAME}:${IMAGE_TAG}
          docker push ${IMAGE_NAME}:latest

          # Save the image name and tag for the deploy stage
          echo "IMAGE_NAME=${IMAGE_NAME}" >> $GITHUB_ENV
          echo "IMAGE_TAG=${IMAGE_TAG}" >> $GITHUB_ENV

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # NEW STEP: Process app.yaml with variable substitution
      - name: Process app.yaml variable substitution
        uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/workflows/app-yaml-substitution-improved.yml@main
        with:
          app_yaml_path: "tfvars/app.yaml"
          output_path: "tfvars/app.yaml.processed"
          environment: ${{ env.ENVIRONMENT }}
          keyvault_name: ${{ vars.KEYVAULT_NAME }}

      # NEW STEP: Move processed file to original location
      - name: Use processed app.yaml
        run: |
          if [ -f "tfvars/app.yaml.processed" ]; then
            mv tfvars/app.yaml.processed tfvars/app.yaml
          fi

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.9.0

      - name: Login to Azure
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TERRAFORM_BACKEND_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TERRAFORM_BACKEND_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ env.ENVIRONMENT }}/container-apps/${{ env.CONTAINER_APP_NAME }}.tfstate"

      - name: Terraform Plan
        run: |
          terraform plan \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -var="location=northeurope" \
            -var="code_name=myteam" \
            -var="environment=${{ env.ENVIRONMENT }}" \
            -var="state_storage_account_name=${{ secrets.TERRAFORM_BACKEND_SA }}" \
            -var="remote_tfstate_rg=${{ secrets.TERRAFORM_BACKEND_RG }}" \
            -var="remote_tfstate_storage_account=${{ secrets.TERRAFORM_BACKEND_SA }}" \
            -var="remote_tfstate_key=${{ env.ENVIRONMENT }}/container-app-environments.tfstate" \
            -var="image_name=${{ env.IMAGE_NAME }}" \
            -var="image_tag=${{ env.IMAGE_TAG }}" \
            -out=tfplan

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
```

## Explanation

This integration:

1. Uses the reusable workflow to process app.yaml with variable substitution
2. Moves the processed file to replace the original app.yaml
3. Maintains all existing Terraform operations

## Where to Store the Python Script

With our solution, you don't need to worry about where to store the Python script:

1. **The script is inlined in the workflow file** - This means you don't need to access any external files
2. **The script is generated at runtime** - It's created in the GitHub Actions runner during execution
3. **The script is available to the calling workflow** - No need to clone additional repositories

## Key Benefits

This approach provides several benefits:

1. **Self-contained** - The workflow includes everything needed to run the substitution
2. **No dependency on external files** - No need to access files from other repositories
3. **Simple to maintain** - All code is in one place
4. **Works across repositories** - Can be called from any repository

## Example Directory Structure

Here's an example of how your repository might be structured:

```
my-container-app/
├── .github/
│   └── workflows/
│       └── deploy-container-app.yml
├── src/
│   └── Dockerfile
└── tfvars/
    └── app.yaml
```

The `app.yaml` file could use variable substitution:

```yaml
# app.yaml
name: ${vars:APP_NAME!} # Required variable
resource_group_name: ${vars:RESOURCE_GROUP:myapp-rg} # With default value
image: ${vars:IMAGE_REGISTRY:ghcr.io}/${vars:IMAGE_REPOSITORY!}:${vars:IMAGE_TAG:latest}
```

When deployed to different environments, the substitution process would replace these variables with the appropriate values from your GitHub environment variables, secrets, or KeyVault.
