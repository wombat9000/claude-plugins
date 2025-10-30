# Testing Guide

This directory contains BATS (Bash Automated Testing System) tests for the dependency-blocker plugin hooks.

## Prerequisites

You need to have BATS installed to run the tests.

### Installing BATS

**macOS (using Homebrew):**
```bash
brew install bats-core
```

**Ubuntu/Debian:**
```bash
sudo apt-get install bats
```

**Using npm:**
```bash
npm install -g bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run all tests:
```bash
bats tests/test-hooks.bats
```

### Run from the plugin root directory:
```bash
cd plugins/dependency-blocker
bats tests/test-hooks.bats
```

### Verbose output:
```bash
bats --tap tests/test-hooks.bats
```

### Run specific test by pattern:
```bash
bats tests/test-hooks.bats --filter "node_modules"
```

## Test Structure

The test suite covers:

1. **bash-validate.sh tests**
   - Should block: Commands referencing `node_modules`, `.git`, `dist`, `build`
   - Should allow: Normal commands in other directories

2. **read-validate.sh tests**
   - Should block: File paths containing excluded directories
   - Should allow: Normal file paths

3. **Edge cases**
   - Similar directory names (e.g., `node_module` vs `node_modules`)
   - Files vs directories (e.g., `.gitignore` vs `.git/`)
   - Partial matches (e.g., `builds.ts` vs `build/`)

## Expected Output

When all tests pass, you'll see:
```
 ✓ bash-validate: blocks ls node_modules
 ✓ bash-validate: blocks find in node_modules
 ✓ bash-validate: blocks cat from .git
 ...
 ✓ edge case: blocks exact dist directory

48 tests, 0 failures
```

## Adding New Tests

To add a new test, add a `@test` block to `test-hooks.bats`:

```bash
@test "description of what you're testing" {
    run "$HOOKS_DIR/bash-validate.sh" "your command here"
    [ "$status" -eq 1 ]  # or -eq 0 for should allow
    [[ "$output" =~ "Blocked" ]]  # optional: check output contains text
}
```

## Continuous Integration

To run these tests in CI, ensure BATS is installed and add to your CI config:

```yaml
# Example GitHub Actions
- name: Install BATS
  run: npm install -g bats

- name: Run tests
  run: bats plugins/dependency-blocker/tests/test-hooks.bats
```

## Troubleshooting

**Tests fail with "permission denied":**
```bash
chmod +x plugins/dependency-blocker/hooks/*.sh
```

**BATS command not found:**
Make sure BATS is installed and in your PATH. Try reinstalling using one of the methods above.
