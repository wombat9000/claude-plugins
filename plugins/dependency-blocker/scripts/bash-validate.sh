#!/bin/bash

# This script validates bash commands before execution.
# It blocks commands that would recurse into excluded directories to avoid token bloat.

# List of excluded directories (critical bloat offenders)
# Each of these can cause massive token waste if accessed
EXCLUDED_DIRS=(
    "node_modules"  # JS/Node dependencies - can be 100k+ files
    ".git"          # Git version control history - entire repo history
    "vendor"        # PHP/Go/Ruby dependencies - like node_modules for other languages
    "target"        # Rust/Java build output - compiled artifacts
    ".venv"         # Python virtual environment - entire stdlib + packages
    "venv"          # Python virtual environment (alternate name)
    "dist"          # Build output - minified/compiled/bundled files
    "build"         # Build output - compiled artifacts and assets
)

# Read input - either JSON from stdin or command-line arguments
if [ $# -gt 0 ]; then
    # Command-line arguments provided (testing mode)
    CMD="$*"
else
    # No arguments, read JSON from stdin (Claude Code hook mode)
    INPUT=$(cat)
    # Extract command from JSON: {"tool_input": {"command": "..."}}
    CMD=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

# Function to check if a directory name appears as a complete path component
contains_excluded_dir() {
    local cmd="$1"
    local dir="$2"

    # Check if directory appears as a complete word/path component
    # Match patterns:
    #   - "dir" at start with space or / after
    #   - "/dir" with space or / after
    #   - space + "dir" + space or /
    #   - "dir" at end
    if [[ "$cmd" =~ (^|[[:space:]]|/)${dir}([[:space:]]|/|$) ]]; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Skip check if no command was extracted
if [ -z "$CMD" ]; then
    exit 0
fi

# Check each excluded directory
for dir in "${EXCLUDED_DIRS[@]}"; do
    if contains_excluded_dir "$CMD" "$dir"; then
        echo "Blocked: Command contains excluded directory '$dir'." >&2
        exit 2
    fi
done

# All checks passed
exit 0
