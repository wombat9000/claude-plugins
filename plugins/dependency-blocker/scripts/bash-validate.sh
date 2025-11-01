#!/bin/bash

# This script validates bash commands before execution.
# It blocks direct access to excluded directories but allows:
# - Tool invocations (npm, yarn, cargo, make, etc.)
# - Tool orchestration with safe navigation (cd dir && npm run build)
#
# Philosophy:
# - Tool invocations safely manage their own directories
# - Safe navigation (cd, pwd, pushd, popd) is allowed
# - Direct access (cat, grep, find, ls) on excluded dirs is blocked
# - Any unsafe command in a chain is treated as direct access

# ============================================
# Configuration
# ============================================

# List of excluded directories (critical bloat offenders)
# Each of these can cause massive token waste if accessed
declare -a EXCLUDED_DIRS=(
    "node_modules"  # JS/Node dependencies - can be 100k+ files
    ".git"          # Git version control history - entire repo history
    "vendor"        # PHP/Go/Ruby dependencies - like node_modules for other languages
    "target"        # Rust/Java build output - compiled artifacts
    ".venv"         # Python virtual environment - entire stdlib + packages
    "venv"          # Python virtual environment (alternate name)
    "dist"          # Build output - minified/compiled/bundled files
    "build"         # Build output - compiled artifacts and assets
)

# List of trusted tool invocations that can safely manage their own directories
declare -a TRUSTED_TOOLS=(
    "npm"           # Node Package Manager
    "yarn"          # Yarn package manager
    "pnpm"          # pnpm package manager
    "cargo"         # Rust package manager
    "make"          # Build automation
    "python"        # Python interpreter (for pip, etc.)
    "go"            # Go compiler
    "ruby"          # Ruby interpreter
    "java"          # Java runtime
    "gradle"        # Gradle build tool
    "maven"         # Maven build tool
    "pip"           # Python package installer
)

# List of truly safe navigation commands
# Note: cd is handled separately - it's allowed unless navigating to excluded dirs
declare -a SAFE_COMMANDS=(
    "pwd"           # Print working directory
    "pushd"         # Push directory
    "popd"          # Pop directory
)

# ============================================
# Helper Functions
# ============================================

# Check if a command is in the safe commands list
is_safe_command() {
    local cmd="$1"
    for safe_cmd in "${SAFE_COMMANDS[@]}"; do
        [[ "$cmd" == "$safe_cmd" ]] && return 0
    done
    return 1
}

# Check if a command is in the trusted tools list
is_trusted_tool() {
    local cmd="$1"
    for tool in "${TRUSTED_TOOLS[@]}"; do
        [[ "$cmd" == "$tool" ]] && return 0
    done
    return 1
}

# Check if a directory name is in the excluded list
is_excluded_directory() {
    local dir_name="$1"
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        [[ "$dir_name" == "$excluded" ]] && return 0
    done
    return 1
}

# Check if text contains an excluded directory as a complete path component
# This ensures we match "node_modules" but not "node_module" or "my_node_modules_backup"
contains_excluded_dir_as_path_component() {
    local text="$1"
    local dir="$2"

    # Match patterns:
    # - Start of string or space or / before dir
    # - End of string or space or / after dir
    if [[ "$text" =~ (^|[[:space:]]|/)${dir}([[:space:]]|/|$) ]]; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Extract the target directory from a cd command
get_cd_target() {
    local segment="$1"
    local target

    # Remove "cd" and leading whitespace
    target="${segment#cd}"
    target="${target#"${target%%[![:space:]]*}"}"  # trim leading whitespace

    # Extract first word (the directory argument)
    target="${target%% *}"

    echo "$target"
}

# Validate a cd command - blocks navigation to excluded directories
validate_cd_command() {
    local segment="$1"
    local target

    target=$(get_cd_target "$segment")

    # Check if the target is an excluded directory
    if is_excluded_directory "$target"; then
        echo "Blocked: Command contains excluded directory '$target'." >&2
        return 1
    fi

    return 0
}

# Check if a segment contains any excluded directories
check_segment_for_excluded_dirs() {
    local segment="$1"

    for dir in "${EXCLUDED_DIRS[@]}"; do
        if contains_excluded_dir_as_path_component "$segment" "$dir"; then
            echo "Blocked: Command contains excluded directory '$dir'." >&2
            return 1
        fi
    done

    return 0
}

# Validate a single command segment
validate_segment() {
    local segment="$1"
    local first_word

    # Trim leading and trailing whitespace
    segment="${segment#"${segment%%[![:space:]]*}"}"  # trim leading
    segment="${segment%"${segment##*[![:space:]]}"}"  # trim trailing

    # Skip empty segments
    [[ -z "$segment" ]] && return 0

    # Extract the first word (the command)
    first_word="${segment%% *}"

    # Special handling for cd - check if it's navigating to an excluded directory
    if [[ "$first_word" == "cd" ]]; then
        validate_cd_command "$segment"
        return $?
    fi

    # Check if the command is safe or trusted
    if is_safe_command "$first_word" || is_trusted_tool "$first_word"; then
        return 0
    fi

    # For unsafe commands, check if they reference excluded directories
    check_segment_for_excluded_dirs "$segment"
    return $?
}

# Split a command by separators (&&, ||, ;) and validate each segment
validate_command() {
    local cmd="$1"
    local segment

    # Replace separators with newlines to split the command
    # This handles: &&, ||, and ;
    local segments
    segments="${cmd//&&/$'\n'}"      # Replace && with newline
    segments="${segments//||/$'\n'}"  # Replace || with newline
    segments="${segments//;/$'\n'}"   # Replace ; with newline

    # Process each segment
    while IFS= read -r segment; do
        if ! validate_segment "$segment"; then
            return 1
        fi
    done <<< "$segments"

    return 0
}

# Parse command from JSON input
parse_json_command() {
    local json="$1"
    local command

    # Extract command from JSON: {"tool_input": {"command": "..."}}
    # Use grep and sed for simple parsing (avoids jq dependency)
    command=$(echo "$json" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')

    echo "$command"
}

# ============================================
# Main Logic
# ============================================

# Read input - either JSON from stdin or command-line arguments
if [ $# -gt 0 ]; then
    # Command-line arguments provided (testing mode)
    CMD="$*"
else
    # No arguments, read JSON from stdin (Claude Code hook mode)
    INPUT=$(cat)
    CMD=$(parse_json_command "$INPUT")
fi

# Skip check if no command was extracted
if [ -z "$CMD" ]; then
    exit 0
fi

# Validate the entire command
if ! validate_command "$CMD"; then
    exit 2
fi

exit 0