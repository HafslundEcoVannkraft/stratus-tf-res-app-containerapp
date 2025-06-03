# GitHub Actions Integration

This document explains how to integrate the variable substitution system with GitHub Actions workflows.

## Overview

The variable substitution system is designed to be lightweight and easily integrated with GitHub Actions workflows. It allows you to use a single YAML configuration file that can be deployed to multiple environments with different values for variables.

## Implementation in GitHub Workflows

### 1. Basic Integration

The variable substitution happens as a preprocessing step before Terraform applies the configuration:

```yaml
- name: Process app.yaml variable substitution
  run: |
    # Simple implementation with jq and envsubst
    cp "$SRC_CODE_PATH/${{ matrix.app }}/app.yaml" terraform-work/tfvars/app.yaml.orig

    # Process substitutions
    python terraform-work/scripts/process_substitutions.py \
      --input terraform-work/tfvars/app.yaml.orig \
      --output terraform-work/tfvars/app.yaml \
      --vars-source github \
      --secrets-source github \
      --kv-source azure-keyvault \
      --environment ${{ inputs.cd_environment }}
```

### 2. Integration with Different Sources

The substitution mechanism supports multiple sources:

- `vars:` - References GitHub Variables
- `secrets:` - References GitHub Secrets
- `kv:` - References Azure KeyVault secrets
- `env:` - References environment variables in the GitHub runner

### 3. Sample Implementation Script

A simple Python implementation for processing substitutions might look like:

```python
import re
import os
import sys
import json
import argparse
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

def process_yaml_substitutions(yaml_content, sources):
    """Process variable substitutions in a YAML string."""
    # Regex to match ${prefix:name:default} or ${prefix:name!}
    pattern = r'\${(vars|secrets|kv|env):([^:!}]+)(?::([^}]+)|!)?}'

    def replace_var(match):
        source_type = match.group(1)
        var_name = match.group(2)
        default_value = match.group(3)
        required = match.group(0).endswith('!}')

        if source_type not in sources:
            if required:
                raise ValueError(f"Source '{source_type}' not configured but required for '{var_name}'")
            return match.group(0)

        value = sources[source_type].get(var_name)

        if value is None:
            if required:
                raise ValueError(f"Required variable '{var_name}' from source '{source_type}' is missing")
            return default_value if default_value is not None else match.group(0)

        return value

    return re.sub(pattern, replace_var, yaml_content)

def main():
    parser = argparse.ArgumentParser(description='Process YAML variable substitutions')
    parser.add_argument('--input', required=True, help='Input YAML file')
    parser.add_argument('--output', required=True, help='Output YAML file')
    parser.add_argument('--vars-source', choices=['github', 'env'], default='github', help='Source for vars:')
    parser.add_argument('--secrets-source', choices=['github', 'env'], default='github', help='Source for secrets:')
    parser.add_argument('--kv-source', choices=['azure-keyvault', 'none'], default='azure-keyvault', help='Source for kv:')
    parser.add_argument('--environment', help='GitHub environment name')
    parser.add_argument('--keyvault-name', help='Azure KeyVault name')
    args = parser.parse_args()

    sources = {}

    # Setup vars source
    if args.vars_source == 'github':
        # For GitHub, we rely on the runner having environment variables set
        # GitHub automatically sets env vars for variables associated with the environment
        vars_dict = {k[6:]: v for k, v in os.environ.items() if k.startswith('VARS_')}
        sources['vars'] = vars_dict
    elif args.vars_source == 'env':
        sources['vars'] = dict(os.environ)

    # Setup secrets source
    if args.secrets_source == 'github':
        # GitHub automatically sets env vars for secrets associated with the environment
        secrets_dict = {k[8:]: v for k, v in os.environ.items() if k.startswith('SECRETS_')}
        sources['secrets'] = secrets_dict
    elif args.secrets_source == 'env':
        # This is for local testing - not recommended for production
        sources['secrets'] = {k[8:]: v for k, v in os.environ.items() if k.startswith('SECRETS_')}

    # Setup KeyVault source
    if args.kv_source == 'azure-keyvault' and args.keyvault_name:
        credential = DefaultAzureCredential()
        keyvault_url = f"https://{args.keyvault_name}.vault.azure.net/"
        client = SecretClient(vault_url=keyvault_url, credential=credential)

        # We don't want to fetch all secrets at once
        # KeyVault values will be fetched on demand
        # For testing, you can use a dictionary
        sources['kv'] = client

    # Read input file
    with open(args.input, 'r') as f:
        yaml_content = f.read()

    # Process substitutions
    try:
        processed_yaml = process_yaml_substitutions(yaml_content, sources)
    except ValueError as e:
        print(f"Error processing substitutions: {str(e)}", file=sys.stderr)
        sys.exit(1)

    # Write output file
    with open(args.output, 'w') as f:
        f.write(processed_yaml)

    print(f"Successfully processed '{args.input}' to '{args.output}'")

if __name__ == '__main__':
    main()
```

## Simplified Workflow Integration

Here's how you would integrate this into your existing workflow:

```yaml
- name: Setup Python for YAML processing
  uses: actions/setup-python@v4
  with:
    python-version: "3.10"

- name: Install required Python packages
  run: |
    pip install pyyaml azure-identity azure-keyvault-secrets

- name: Process app.yaml substitutions
  run: |
    # Process the app.yaml file and replace variables
    python terraform-work/scripts/process_substitutions.py \
      --input "$SRC_CODE_PATH/${{ matrix.app }}/app.yaml" \
      --output terraform-work/tfvars/app.yaml \
      --environment ${{ inputs.cd_environment }} \
      --keyvault-name "${{ vars.KEYVAULT_NAME }}"
  env:
    # This ensures GitHub vars/secrets are available to the script
    AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
    AZURE_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
    AZURE_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

## Benefits of This Implementation

1. **Clean Separation**: The variable substitution is a separate step that doesn't interfere with the rest of your workflow
2. **Multiple Sources**: Variables can come from GitHub variables, secrets, Azure KeyVault, or environment variables
3. **Flexible**: The same YAML configuration can be deployed to different environments
4. **Simple**: The implementation is straightforward and doesn't require complex dependencies

## Practical Example with Your Workflow

In your specific workflow, you'd add the substitution step in the `terraform-work` job, after copying the app.yaml file and before running Terraform operations:

```yaml
- name: Copy app.yaml file and validate
  run: |
    YAML_PATH="$SRC_CODE_PATH/${{ matrix.app }}/app.yaml"
    if [ -f "$YAML_PATH" ]; then
      cp "$YAML_PATH" terraform-work/tfvars/app.yaml.orig
    else
      echo "No app.yaml found for ${{ matrix.app }}, skipping copy."
    fi

# NEW STEP ADDED HERE
- name: Process app.yaml substitutions
  if: fileExists('terraform-work/tfvars/app.yaml.orig')
  run: |
    # Process substitutions
    python terraform-work/scripts/process_substitutions.py \
      --input terraform-work/tfvars/app.yaml.orig \
      --output terraform-work/tfvars/app.yaml \
      --environment ${{ inputs.cd_environment }} \
      --keyvault-name "${{ vars.KEYVAULT_NAME }}"
```

## Fallback for Compatibility

If you want backward compatibility, you could make this step conditional:

```yaml
- name: Check if app.yaml uses substitution syntax
  id: check_substitution
  if: fileExists('terraform-work/tfvars/app.yaml.orig')
  run: |
    if grep -q '\${.*}' terraform-work/tfvars/app.yaml.orig; then
      echo "USES_SUBSTITUTION=true" >> $GITHUB_OUTPUT
    else
      echo "USES_SUBSTITUTION=false" >> $GITHUB_OUTPUT
    fi

- name: Process app.yaml substitutions
  if: steps.check_substitution.outputs.USES_SUBSTITUTION == 'true'
  run: |
    # Process substitutions only if the file uses the ${...} syntax
    python terraform-work/scripts/process_substitutions.py \
      --input terraform-work/tfvars/app.yaml.orig \
      --output terraform-work/tfvars/app.yaml \
      --environment ${{ inputs.cd_environment }}

- name: Use original app.yaml (no substitution)
  if: steps.check_substitution.outputs.USES_SUBSTITUTION != 'true' && fileExists('terraform-work/tfvars/app.yaml.orig')
  run: |
    # If no substitution is used, just use the original file
    cp terraform-work/tfvars/app.yaml.orig terraform-work/tfvars/app.yaml
```

This approach ensures that existing app.yaml files without substitutions will continue to work without any changes.
