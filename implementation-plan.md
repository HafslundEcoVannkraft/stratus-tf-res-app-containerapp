### Updated Implementation Plan for Container App Wrapper Module

This implementation plan outlines the final steps needed to fully implement the variable substitution system within the Container App wrapper module.

## 1. Implementation Components

### 1.1 Scripts

- ✅ `process_substitutions.py`: Script to process variable substitution in app.yaml
  - Supports multiple sources (vars, secrets, kv, env)
  - Handles required variables and defaults

### 1.2 Workflows

- ✅ `app-yaml-substitution.yml`: Reusable workflow for processing app.yaml files
  - Can be called from any container app deployment workflow
  - Handles authentication for KeyVault if needed

### 1.3 Documentation

- ✅ `github_integration.md`: Explains how to integrate with GitHub workflows
- ✅ `variable_substitution_example.md`: Shows examples of variable substitution
- ✅ `variable_substitution.md`: Documents the syntax and capabilities

## 2. Integration Plan

### 2.1 Update Container App Deploy Workflow

Integrate the variable substitution workflow into the existing container app deployment workflow:

1. In `stratus-lz-workflows/.github/workflows/container_app_deploy.yaml`:

```yaml
# After copying app.yaml file
- name: Process app.yaml variable substitution
  uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/workflows/app-yaml-substitution.yml@main
  with:
    app_yaml_path: terraform-work/tfvars/app.yaml.orig
    output_path: terraform-work/tfvars/app.yaml
    environment: ${{ inputs.cd_environment }}
    keyvault_name: ${{ vars.KEYVAULT_NAME }}
```

2. Update the copy step to save as app.yaml.orig:

```yaml
- name: Copy app.yaml file
  run: |
    YAML_PATH="$SRC_CODE_PATH/${{ matrix.app }}/app.yaml"
    if [ -f "$YAML_PATH" ]; then
      mkdir -p terraform-work/tfvars
      cp "$YAML_PATH" terraform-work/tfvars/app.yaml.orig
    else
      echo "No app.yaml found for ${{ matrix.app }}, skipping copy."
    fi
```

### 2.2 Release Process

1. Create GitHub repository for the script:

   - Copy scripts to `.github/scripts/` directory
   - Move workflows to `.github/workflows/` directory
   - Update documentation to reference correct paths

2. Publish the reusable workflow:

   - Tag with version number for stable references
   - Document how to reference from other workflows

3. Update container app demo repository:
   - Update app.yaml files to use variable substitution
   - Test deployment to different environments

### 2.3 Backward Compatibility

The implementation includes backward compatibility features:

- Files without substitution syntax are copied without processing
- Default values allow gradual adoption
- Script has comprehensive error handling

## 3. Testing Plan

### 3.1 Local Testing

1. Manual testing with sample app.yaml files:

   - Test with different variable sources
   - Test error cases (missing required variables)
   - Test default values

2. Unit tests for the substitution script:
   - Test regex patterns
   - Test error handling
   - Test different source configurations

### 3.2 Integration Testing

1. Deploy to dev environment:

   - Test with minimal variables
   - Verify all substitutions are applied correctly

2. Deploy to test/prod environments:
   - Test with environment-specific variables
   - Test KeyVault integration

## 4. Documentation Updates

### 4.1 Update README.md

Add section about variable substitution:

```markdown
## Variable Substitution

This module supports variable substitution in app.yaml files, allowing you to:

- Reference GitHub Variables: `${vars:VARIABLE_NAME}`
- Reference GitHub Secrets: `${secrets:SECRET_NAME}`
- Reference Azure KeyVault secrets: `${kv:SECRET_NAME}`
- Reference environment variables: `${env:ENV_VAR}`

For more information, see [Variable Substitution Documentation](./doc/variable_substitution.md).
```

### 4.2 Update Examples

Update examples to demonstrate variable substitution:

- Simple example with basic substitution
- Complex example with multiple sources
- Example showing environment-specific configurations

## 5. Final Deliverables

1. Scripts in `.github/scripts/` directory
2. Workflow in `.github/workflows/` directory
3. Documentation in `doc/` directory
4. Example app.yaml files with substitution
5. Unit tests for the substitution script

## 6. Timeline

1. Development & Testing: 2 days
2. Documentation & Examples: 1 day
3. Integration with existing workflows: 1 day
4. Final validation: 1 day

Total implementation time: 5 days
