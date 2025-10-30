#!/bin/bash

# This script validates bash commands before execution.
# It blocks commands that would recurse into excluded directories to avoid token bloat.

# List of excluded directories
EXCLUDED_DIRS=("node_modules" ".git" "dist" "build")

# The bash command to validate is passed as arguments
CMD="$*"

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

# Check each excluded directory
for dir in "${EXCLUDED_DIRS[@]}"; do
    if contains_excluded_dir "$CMD" "$dir"; then
        echo "Blocked: Command contains excluded directory '$dir'."
        exit 1
    fi
done

# All checks passed
exit 0
