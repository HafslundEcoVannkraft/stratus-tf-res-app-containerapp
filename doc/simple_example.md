# Basic Azure Container App Example

This example demonstrates deploying a minimal web application with:

- External ingress
- Basic scaling
- Single container

## YAML Configuration

```yaml
name: "simple-app"
revision_mode: "Single"
container_app_environment_target: "default" # Target the default environment in the remote state

# Note: resource_group_name and container_app_environment_resource_id are now
# automatically sourced from remote state

template:
  max_replicas: 5
  min_replicas: 1

  containers:
    - name: "simple-app"
      # image: "myregistry.azurecr.io/simple-app:latest" # Uncomment to override the image built by GitHub workflow
      cpu: 0.25
      memory: "0.5Gi"
      env:
        - name: "ENVIRONMENT"
          value: "${vars:ENVIRONMENT:dev}"
        - name: "LOG_LEVEL"
          value: "${vars:LOG_LEVEL:INFO}"

      liveness_probes:
        - transport: "HTTP"
          port: 8080
          path: "/health"

ingress:
  external_enabled: true
  target_port: 8080

tags:
  Environment: "Development"
  Department: "IT"
```

## Terraform Module Usage

```hcl
module "simple_app" {
  source = "github.com/HafslundEcoVannkraft/stratus-tf-res-app-containerapp"

  subscription_id            = "00000000-0000-0000-0000-000000000000"
  location                   = "northeurope"
  code_name                  = "myteam"
  environment                = "dev"
  state_storage_account_name = "stratusstate"

  # Remote state configuration for Container App Environment
  remote_tfstate_rg            = "rg-tfstate"
  remote_tfstate_storage_account = "stratustfstate"
  remote_tfstate_container     = "tfstate"
  remote_tfstate_key           = "env/container-apps.tfstate"

  # Container image details
  image_name                  = "mcr.microsoft.com/dotnet/samples"
  image_tag                   = "aspnetapp"
}
```
