#!/usr/bin/env python3
"""
Variable Substitution Processor for Container App YAML Files

This script processes variable substitution patterns in YAML files used for
Container App deployments. It supports multiple sources for variables:
- GitHub Variables (vars:)
- GitHub Secrets (secrets:)
- Azure KeyVault (kv:)
- Environment Variables (env:)

Usage:
  python process_substitutions.py --input app.yaml.orig --output app.yaml --environment dev

Substitution syntax in YAML:
  ${vars:VARIABLE_NAME:default_value}   - Variable with default
  ${vars:VARIABLE_NAME!}                - Required variable
  ${secrets:SECRET_NAME}                - Secret
  ${kv:KEYVAULT_SECRET}                 - KeyVault secret
  ${env:ENV_VAR}                        - Environment variable
"""

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

        # Special handling for KeyVault source
        if source_type == 'kv' and hasattr(sources[source_type], 'get_secret'):
            try:
                # Fetch secret from KeyVault on demand
                value = sources[source_type].get_secret(var_name).value
            except Exception as e:
                if required:
                    raise ValueError(f"Failed to retrieve required KeyVault secret '{var_name}': {str(e)}")
                value = None
        else:
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
        vars_dict = {k[5:]: v for k, v in os.environ.items() if k.startswith('VARS_')}
        sources['vars'] = vars_dict
    elif args.vars_source == 'env':
        sources['vars'] = dict(os.environ)

    # Setup secrets source
    if args.secrets_source == 'github':
        # GitHub automatically sets env vars for secrets associated with the environment
        secrets_dict = {k[7:]: v for k, v in os.environ.items() if k.startswith('SECRETS_')}
        sources['secrets'] = secrets_dict
    elif args.secrets_source == 'env':
        # This is for local testing - not recommended for production
        sources['secrets'] = {k[7:]: v for k, v in os.environ.items() if k.startswith('SECRETS_')}

    # Setup KeyVault source
    if args.kv_source == 'azure-keyvault' and args.keyvault_name:
        credential = DefaultAzureCredential()
        keyvault_url = f"https://{args.keyvault_name}.vault.azure.net/"
        client = SecretClient(vault_url=keyvault_url, credential=credential)

        # We don't want to fetch all secrets at once
        # KeyVault values will be fetched on demand
        sources['kv'] = client

    # Always include environment variables as a source
    sources['env'] = dict(os.environ)

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
