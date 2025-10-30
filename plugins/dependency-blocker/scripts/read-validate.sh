#!/bin/bash

# This script validates read operations before execution.
# It blocks reads from excluded directories to avoid token bloat.

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
    FILE_PATH="$1"
else
    # No arguments, read JSON from stdin (Claude Code hook mode)
    INPUT=$(cat)
    # Extract file_path from JSON: {"tool_input": {"file_path": "..."}}
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

# Function to check if a directory name appears as a complete path component
contains_excluded_dir() {
    local path="$1"
    local dir="$2"

    # Check if directory appears as a complete path component
    # Match patterns:
    #   - "dir" at start with / after
    #   - "/dir/" in the middle
    #   - "/dir" at end
    if [[ "$path" =~ (^|/)${dir}(/|$) ]]; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Skip check if no file path was extracted
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Check each excluded directory
for dir in "${EXCLUDED_DIRS[@]}"; do
    if contains_excluded_dir "$FILE_PATH" "$dir"; then
        echo "Blocked: File path contains excluded directory '$dir'." >&2
        exit 2
    fi
done

# All checks passed
exit 0
