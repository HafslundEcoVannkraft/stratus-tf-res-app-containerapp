# Container App Variable Substitution Example

This example demonstrates how to use variable substitution in your Container App YAML configuration.

## Basic app.yaml with Variable Substitution

```yaml
# app.yaml
name: ${vars:APP_NAME!} # Required variable
resource_group_name: ${vars:RESOURCE_GROUP:myapp-rg} # With default value
image: ${vars:IMAGE_REGISTRY:ghcr.io}/${vars:IMAGE_REPOSITORY!}:${vars:IMAGE_TAG:latest}

# Environment variables - these will be passed to the container
environment_variables:
  - name: DATABASE_URL
    value: ${secrets:DB_CONNECTION_STRING!} # Required secret
  - name: API_KEY
    value: ${kv:API_KEY} # From KeyVault
  - name: LOG_LEVEL
    value: ${vars:LOG_LEVEL:INFO} # With default value
  - name: SERVICE_BUS_CONNECTION
    value: ${secrets:SERVICE_BUS_CONNECTION}
  - name: ASPNETCORE_ENVIRONMENT
    value: ${env:ASPNETCORE_ENVIRONMENT:Production} # From environment var with default

# Ingress configuration
ingress:
  external_enabled: true
  target_port: 8080
  transport: auto
  traffic_weight:
    - percentage: 100
      latest_revision: true

# Container configuration
container:
  cpu: ${vars:CONTAINER_CPU:0.5}
  memory: ${vars:CONTAINER_MEMORY:1.0}Gi

# Scale configuration
scale:
  min_replicas: ${vars:MIN_REPLICAS:1}
  max_replicas: ${vars:MAX_REPLICAS:10}
```

## Integration with GitHub Actions

In your GitHub Actions workflow, you would process this file using the provided script:

```yaml
- name: Process app.yaml substitutions
  run: |
    python scripts/process_substitutions.py \
      --input path/to/app.yaml \
      --output processed/app.yaml \
      --environment ${{ github.event.inputs.environment }} \
      --keyvault-name "myproject-kv"
  env:
    # Make GitHub variables and secrets available
    VARS_APP_NAME: ${{ vars.APP_NAME }}
    VARS_IMAGE_REPOSITORY: ${{ vars.IMAGE_REPOSITORY }}
    VARS_IMAGE_TAG: ${{ github.event.inputs.tag || 'latest' }}
    SECRETS_DB_CONNECTION_STRING: ${{ secrets.DB_CONNECTION_STRING }}
    # The Azure identity will be used to access KeyVault
```

## Processed Output Example

After processing, the app.yaml would look like:

```yaml
# app.yaml (processed)
name: my-awesome-app
resource_group_name: myapp-rg
image: ghcr.io/myorganization/my-awesome-app:v1.2.3

# Environment variables
environment_variables:
  - name: DATABASE_URL
    value: "Server=mydb.database.windows.net;Database=mydb;User Id=dbuser;Password=dbpassword;"
  - name: API_KEY
    value: "api-key-from-keyvault"
  - name: LOG_LEVEL
    value: "INFO"
  - name: SERVICE_BUS_CONNECTION
    value: "Endpoint=sb://myservicebus.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=mykey"
  - name: ASPNETCORE_ENVIRONMENT
    value: "Production"

# Ingress configuration
ingress:
  external_enabled: true
  target_port: 8080
  transport: auto
  traffic_weight:
    - percentage: 100
      latest_revision: true

# Container configuration
container:
  cpu: 1.0
  memory: 2.0Gi

# Scale configuration
scale:
  min_replicas: 2
  max_replicas: 5
```

## Advanced Usage

You can combine different sources in the same string:

```yaml
connection_string: "Server=${secrets:DB_SERVER};Database=${secrets:DB_NAME};User Id=${kv:DB_USER};Password=${kv:DB_PASSWORD};"
```

## Multiple Environment Support

With this approach, you can use the same app.yaml file for different environments:

Development:

```
VARS_APP_NAME=myapp-dev
VARS_MIN_REPLICAS=1
SECRETS_DB_CONNECTION_STRING=<dev-connection-string>
```

Production:

```
VARS_APP_NAME=myapp-prod
VARS_MIN_REPLICAS=3
VARS_MAX_REPLICAS=20
SECRETS_DB_CONNECTION_STRING=<prod-connection-string>
```

The variable substitution system will use the appropriate values for each environment.
