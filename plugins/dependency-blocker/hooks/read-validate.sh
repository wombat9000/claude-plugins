#!/bin/bash

# This script validates read operations before execution.
# It blocks reads from excluded directories to avoid token bloat.

# List of excluded directories
EXCLUDED_DIRS=("node_modules" ".git" "dist" "build")

# The file path to validate is passed as the first argument
FILE_PATH="$1"

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

# Check each excluded directory
for dir in "${EXCLUDED_DIRS[@]}"; do
    if contains_excluded_dir "$FILE_PATH" "$dir"; then
        echo "Blocked: File path contains excluded directory '$dir'."
        exit 1
    fi
done

# All checks passed
exit 0
