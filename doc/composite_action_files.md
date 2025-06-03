# Using Separate Script Files with Composite Actions

This document explains the approach we're using for the YAML variable substitution composite action.

## How Composite Actions Access Files

There are important differences in how files are accessed when a composite action is used:

1. **Same Repository Usage**:

   - When using the action within its own repository, it has access to all files in that repository
   - The script file can be accessed directly using `$GITHUB_ACTION_PATH`

2. **Cross-Repository Usage**:
   - When using the action from a different repository, only the `action.yml` file itself is fetched
   - Any other files in the action's repository are not available
   - The action needs a fallback mechanism

## Our Hybrid Approach

We've implemented a hybrid approach that works in both scenarios:

1. **Try the External Script First**:

   - Check if the script file exists at `$GITHUB_ACTION_PATH/process_substitutions.py`
   - If it exists (same repository usage), use that file

2. **Fallback to Inline Script**:
   - If the script doesn't exist (cross-repository usage), create it inline
   - This ensures the action works everywhere

## Benefits of This Approach

1. **Maintainability**: The script can be maintained as a separate file for easier development
2. **Consistency**: The action works the same way regardless of where it's called from
3. **No External Dependencies**: No need to checkout repositories or download files

## Best Practices for GitHub Action Development

When developing composite actions that need to access files:

1. **Use `$GITHUB_ACTION_PATH`**: This environment variable points to the root of your action
2. **Always Include a Fallback**: Don't assume files will be available
3. **Consider Both Usage Scenarios**: Test both same-repo and cross-repo usage

## Example Implementation

```yaml
# Try to use the script from the current repository first
- name: Check for script in the repository
  id: check_script
  shell: bash
  run: |
    SCRIPT_PATH="${GITHUB_ACTION_PATH}/process_substitutions.py"
    if [ -f "$SCRIPT_PATH" ]; then
      echo "SCRIPT_EXISTS=true" >> $GITHUB_OUTPUT
      echo "SCRIPT_PATH=$SCRIPT_PATH" >> $GITHUB_OUTPUT
    else
      echo "SCRIPT_EXISTS=false" >> $GITHUB_OUTPUT
    fi

# Create the script if it doesn't exist
- name: Create substitution script if needed
  id: create_script
  if: steps.check_script.outputs.SCRIPT_EXISTS != 'true'
  shell: bash
  run: |
    cat > process_substitutions.py << 'EOF'
    # Script content here
EOF
    chmod +x process_substitutions.py
    echo "SCRIPT_PATH=$(pwd)/process_substitutions.py" >> $GITHUB_OUTPUT
```

## Conclusion

This approach gives us the best of both worlds: a separate, maintainable script file for normal development, plus the ability to use the action from any repository without dependencies.
