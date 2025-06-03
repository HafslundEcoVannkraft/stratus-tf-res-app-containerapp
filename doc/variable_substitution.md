# Variable Substitution in YAML Configuration

This document provides examples of how to use variable substitution in your Container App YAML configuration files.

## Basic Syntax

Variable substitution uses the `${variable_name}` syntax:

```yaml
env:
  - name: "API_ENDPOINT"
    value: "${api_endpoint}"
```

## Source-Specific Variables

You can explicitly specify the source using prefixes:

```yaml
env:
  - name: "API_KEY"
    value: "${secrets:api_key}" # From GitHub Secrets
  - name: "ENVIRONMENT"
    value: "${vars:environment}" # From GitHub Variables
  - name: "DB_PASSWORD"
    value: "${kv:database-password}" # From Azure KeyVault
  - name: "DEBUG"
    value: "${env:DEBUG_FLAG}" # From GitHub Runner environment
```

## Default Values

You can specify default values for variables:

```yaml
env:
  - name: "LOG_LEVEL"
    value: "${vars:log_level:INFO}" # Default to "INFO" if not set
  - name: "TIMEOUT"
    value: "${vars:timeout:30}" # Default to "30" if not set
```

## Required Variables

Mark variables as required (deployment will fail if missing):

```yaml
env:
  - name: "DB_CONNECTION"
    value: "${kv:database-connection!}" # Required variable
  - name: "API_KEY"
    value: "${secrets:api_key!}" # Required variable
```

## Common Patterns

### Environment Configuration

```yaml
env:
  - name: "ENVIRONMENT"
    value: "${vars:ENVIRONMENT:development}"
  - name: "API_URL"
    value: "${vars:API_URL:https://api-dev.example.com}"
```

### Secrets Management

```yaml
env:
  - name: "DB_PASSWORD"
    value: "${secrets:db_password!}"
  - name: "API_KEY"
    value: "${kv:api-key!}"
```

### Feature Flags

```yaml
env:
  - name: "FEATURE_X_ENABLED"
    value: "${vars:FEATURE_X:false}"
  - name: "FEATURE_Y_ENABLED"
    value: "${vars:FEATURE_Y:false}"
```

### Connection Strings with Fallbacks

```yaml
env:
  - name: "PRIMARY_CONNECTION"
    value: "${kv:primary-connection}"
  - name: "BACKUP_CONNECTION"
    value: "${kv:backup-connection:${kv:primary-connection}}" # Use primary if backup not set
```

### Substitution in Other Sections

Variables can be used in almost any part of the YAML configuration:

```yaml
# In template section
template:
  min_replicas: "${vars:MIN_REPLICAS:1}"
  max_replicas: "${vars:MAX_REPLICAS:10}"

# In ingress section
ingress:
  target_port: "${vars:APP_PORT:8080}"

# In custom domains
custom_domains:
  domain1:
    name: "${vars:DOMAIN_NAME:app.example.com}"

# In secrets
secrets:
  db-secret:
    name: "DB_SECRET"
    value: "${secrets:database_secret}"
```

## Recommendations

1. Use `vars:` for non-sensitive configuration values
2. Use `secrets:` or `kv:` for sensitive values
3. Add the `!` suffix for required values
4. Provide sensible defaults where appropriate
5. Use `env:` when you need runtime flexibility
