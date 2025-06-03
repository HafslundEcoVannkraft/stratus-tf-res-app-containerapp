# GitHub Actions Integration

This document explains how to integrate the variable substitution system with GitHub Actions workflows.

## Overview

The variable substitution system is designed to be lightweight and easily integrated with GitHub Actions workflows. It allows you to use a single YAML configuration file that can be deployed to multiple environments with different values for variables.

## Implementation in GitHub Workflows

### 1. Inline Script Approach

The key insight for implementation is to **inline the Python script directly in the workflow file**. This eliminates the need to access external files from other repositories.

```yaml
- name: Create substitution script
  run: |
    cat > process_substitutions.py << 'EOF'
#!/usr/bin/env python3
"""
Variable Substitution Processor for Container App YAML Files
"""
import re
import os
import sys
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# Processing logic here
EOF

    chmod +x process_substitutions.py

- name: Process app.yaml substitutions
  run: |
    python process_substitutions.py \
      --input "app.yaml" \
      --output "app.yaml.processed" \
      --environment "${{ inputs.environment }}"
```

### 2. Reusable Workflow

We've created a reusable workflow at `.github/workflows/app-yaml-substitution-improved.yml` that:

1. Creates the Python script at runtime
2. Processes the YAML file with variable substitution
3. Handles backward compatibility for files without substitution

### 3. Integration with Different Sources

The substitution mechanism supports multiple sources:

- `vars:` - References GitHub Variables
- `secrets:` - References GitHub Secrets
- `kv:` - References Azure KeyVault secrets
- `env:` - References environment variables in the GitHub runner

## Using the Reusable Workflow

To use the reusable workflow in your own workflows:

```yaml
- name: Process app.yaml variable substitution
  uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/workflows/app-yaml-substitution-improved.yml@main
  with:
    app_yaml_path: "tfvars/app.yaml"
    output_path: "tfvars/app.yaml.processed"
    environment: ${{ env.ENVIRONMENT }}
    keyvault_name: ${{ vars.KEYVAULT_NAME }}

- name: Use processed app.yaml
  run: |
    if [ -f "tfvars/app.yaml.processed" ]; then
      mv tfvars/app.yaml.processed tfvars/app.yaml
    fi
```

## Benefits of This Implementation

1. **Self-contained**: The workflow includes everything needed to run the substitution
2. **No dependency on external files**: No need to access files from other repositories
3. **Simple to maintain**: All code is in one place
4. **Works across repositories**: Can be called from any repository

## Practical Example

For a complete example of integrating this with an existing workflow, see [Workflow Integration Example](workflow_integration_example.md).

## Fallback for Compatibility

The implementation includes backward compatibility features:

- Files without substitution syntax are copied without processing
- Default values allow gradual adoption
- Script has comprehensive error handling

This approach ensures that existing app.yaml files without substitutions will continue to work without any changes.
