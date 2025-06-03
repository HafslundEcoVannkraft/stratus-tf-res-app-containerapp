## Implementing a Composite Action vs Other Options

When implementing variable substitution for Container Apps, there are several approaches we can consider:

### 1. Composite Action (Recommended)

A composite action is the most elegant solution for this task, combining multiple steps into a reusable unit that runs within the same job.

**Implementation**: [See the implementation here](/.github/actions/yaml-variable-substitution/action.yml)

**Benefits:**

- Runs in the same job as the caller workflow
- Simplifies file handling (no cross-job file transfers)
- Easy to use with `uses:` syntax
- Can access and modify files directly in the workspace
- Perfect for operations that need to be part of a larger workflow

**Example Usage:**

```yaml
- name: Process app.yaml variable substitution
  uses: HafslundEcoVannkraft/stratus-tf-res-app-containerapp/.github/actions/yaml-variable-substitution@main
  with:
    app_yaml_path: "tfvars/app.yaml"
    output_path: "tfvars/app.yaml.processed"
```

### 2. Reusable Workflow

A reusable workflow is an alternative approach that creates a separate job for the variable substitution.

**Implementation**: [See the implementation here](/workflows/app-yaml-substitution-improved.yml)

**Benefits:**

- Can be called from any workflow with `uses:` syntax
- Supports job-level configuration like environment
- Has its own runner and resources

**Drawbacks:**

- Requires file copying between jobs
- More complex integration
- Cannot directly access files in the caller workflow

### 3. JavaScript Action

A full GitHub Action implemented in JavaScript is another option, especially if we want to publish it to the GitHub Marketplace.

**Benefits:**

- Can be published to the GitHub Marketplace
- More sophisticated error handling and logging
- Better integration with GitHub APIs

**Drawbacks:**

- More complex to develop and maintain
- Overkill for our specific use case

## Recommendation

The **Composite Action** approach is recommended because:

1. It balances simplicity with functionality
2. It runs in the same job, simplifying file handling
3. It provides all the necessary features for variable substitution
4. It's easier to maintain and understand

## Next Steps

1. Use the composite action in your workflows
2. Consider creating a standalone repository for this action if it needs to be shared across many organizations
3. Version the action using tags for stable references
