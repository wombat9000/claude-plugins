# Dependency Blocker Plugin

Prevents Claude from accessing dependency directories to save tokens and improve performance.

## Overview

The Dependency Blocker plugin automatically blocks Claude Code from reading or executing bash commands that access common dependency and build directories. This prevents token waste when Claude attempts to search through large directories like `node_modules`, `.git`, `dist`, or `build`.

## Features

- **Bash Command Validation**: Blocks bash commands that reference excluded directories
- **Read Validation**: Prevents file reads from excluded directories
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

To add more directories to the exclusion list, edit the `EXCLUDED_DIRS` array in both scripts:

**scripts/bash-validate.sh** and **scripts/read-validate.sh**:
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

The plugin uses two validation hooks:

1. **bashValidate**: Runs before any bash command execution
2. **readValidate**: Runs before any file read operation

When Claude attempts to access a blocked directory, the hook will:
1. Check if the path/command contains any excluded directory pattern
2. Block the operation and display an informative message
3. Return exit code 1 to prevent execution

## Example Usage

When Claude tries to run:
```bash
find node_modules -name "*.js"
```

The plugin blocks it with:
```
Blocked: Command contains excluded directories (node_modules|\.git|dist|build).
```

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

The test suite includes 46 tests covering:
- **Command-line mode tests (42 tests)**: Direct script invocation with arguments
- **JSON input mode tests (4 tests)**: Claude Code hook format via stdin
- Bash command validation for all 8 excluded directories
- File read validation for all 8 excluded directories
- Edge cases to prevent false positives (similar names, partial matches, etc.)

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Version

**1.0.0**

## License

MIT

## Support

For issues or questions, please open an issue on the marketplace repository.
