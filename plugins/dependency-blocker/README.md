# Dependency Blocker Plugin

Prevents Claude from accessing dependency directories to save tokens and improve performance.

## Overview

The Dependency Blocker plugin automatically blocks Claude Code from reading or executing bash commands that access common dependency and build directories. This prevents token waste when Claude attempts to search through large directories like `node_modules`, `.git`, `dist`, or `build`.

## Features

- **Bash Command Validation**: Blocks bash commands that reference excluded directories
- **Read Validation**: Prevents file reads from excluded directories
- **Glob Validation**: Blocks glob patterns that target excluded directories
- **Grep Validation**: Blocks grep searches in excluded directories
- **Configurable**: Easy to customize excluded directory patterns
- **Token Efficient**: Saves significant tokens by preventing unnecessary directory access

## Installation

### From Marketplace

```shell
/plugin install dependency-blocker@wombat9000-marketplace
```

## Blocked Directories

By default, the following directories are blocked (critical bloat offenders that cause massive token waste):

### JavaScript/Node.js
- `node_modules` - Can contain 100k+ dependency files

### Version Control
- `.git` - Entire repository history

### Multi-Language Dependencies
- `vendor` - PHP/Go/Ruby dependencies (like node_modules)

### Build Outputs
- `target` - Rust/Java compiled artifacts
- `dist` - Minified/compiled/bundled output
- `build` - Compiled artifacts and assets

### Python
- `.venv` - Python virtual environment (entire stdlib + packages)
- `venv` - Python virtual environment (alternate name)

## Customization

To add more directories to the exclusion list, edit the `EXCLUDED_DIRS` array in all validation scripts:

**scripts/bash-validate.sh**, **scripts/read-validate.sh**, **scripts/glob-validate.sh**, and **scripts/grep-validate.sh**:
```bash
EXCLUDED_DIRS=(
    "node_modules"
    ".git"
    "vendor"
    "target"
    ".venv"
    "venv"
    "dist"
    "build"
    # Add your own directories here:
    # "__pycache__"
    # ".pytest_cache"
    # "coverage"
)
```

## How It Works

The plugin uses four validation hooks that run before tool execution:

1. **Bash**: Validates bash command executions
2. **Read**: Validates file read operations
3. **Glob**: Validates file pattern matching operations
4. **Grep**: Validates content search operations

When Claude attempts to access a blocked directory, the hook will:
1. Check if the path/command/pattern contains any excluded directory
2. Block the operation and display an informative message to Claude
3. Return exit code 2 to prevent execution

## Example Usage

### Blocked Operations

**Bash command:**
```bash
find node_modules -name "*.js"
```
Blocked with: `Blocked: Command contains excluded directory 'node_modules'.`

**Glob pattern:**
```bash
node_modules/**/*.js
```
Blocked with: `Blocked: Glob pattern 'node_modules/**/*.js' targets excluded directory 'node_modules'.`

**Grep search:**
```bash
grep -r "import" node_modules/
```
Blocked with: `Blocked: Grep path 'node_modules/' is in excluded directory 'node_modules'.`

**Read operation:**
```bash
cat node_modules/react/package.json
```
Blocked with: `Blocked: File path contains excluded directory 'node_modules'.`

## Benefits

- **Faster Responses**: Avoid waiting for operations on large directories
- **Token Savings**: Don't waste tokens reading thousands of dependency files
- **Better Focus**: Keep Claude focused on your actual source code
- **Improved Performance**: Reduce unnecessary file system operations

## Testing

This plugin includes a comprehensive test suite using BATS (Bash Automated Testing System).

### Prerequisites

Install BATS:

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# npm
npm install -g bats
```

### Running Tests

```bash
# Run all tests
bats plugins/dependency-blocker/tests/test-hooks.bats

# Or from the plugin directory
cd plugins/dependency-blocker
bats tests/test-hooks.bats
```

### Test Coverage

The test suite includes 80 tests covering:
- **Bash validation (16 tests)**: Command-line and JSON input modes
- **Read validation (16 tests)**: File path validation
- **Glob validation (14 tests)**: Pattern matching validation
- **Grep validation (20 tests)**: Search path validation
- **JSON input tests (4 tests)**: Claude Code hook format via stdin
- **Edge cases (10 tests)**: Prevent false positives (similar names, partial matches, etc.)

All validation scripts cover all 8 excluded directories.

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Version

**1.0.0**

## License

MIT

## Support

For issues or questions, please open an issue on the marketplace repository.
