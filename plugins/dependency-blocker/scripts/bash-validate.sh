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

# List of trusted tool invocations that can safely manage their own directories
TRUSTED_TOOLS=(
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
# Note: cd is NOT included here - it will be validated separately
SAFE_COMMANDS=(
    "pwd"           # Print working directory
    "pushd"         # Push directory
    "popd"          # Pop directory
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

# Skip check if no command was extracted
if [ -z "$CMD" ]; then
    exit 0
fi

# Function to check if a command (first word) is safe/trusted
is_safe_or_trusted() {
    local cmd="$1"

    # Check safe commands
    for safe in "${SAFE_COMMANDS[@]}"; do
        [[ "$cmd" == "$safe" ]] && return 0
    done

    # Check trusted tools
    for tool in "${TRUSTED_TOOLS[@]}"; do
        [[ "$cmd" == "$tool" ]] && return 0
    done

    return 1
}

# Function to check if a directory name appears as a complete path component
contains_excluded_dir() {
    local text="$1"
    local dir="$2"

    if [[ "$text" =~ (^|[[:space:]]|/)${dir}([[:space:]]|/|$) ]]; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Function to validate command segments separated by &&, ||, ;
# Each segment's first word must be a safe command or trusted tool,
# otherwise the entire segment is checked for excluded directory access
validate_segments() {
    local cmd="$1"
    local awkprog

    read -r -d '' awkprog << 'AWKEOF'
    BEGIN {
        # Build safe commands lookup
        safe["pwd"] = 1
        safe["pushd"] = 1
        safe["popd"] = 1

        # Build trusted tools lookup
        trusted["npm"] = 1
        trusted["yarn"] = 1
        trusted["pnpm"] = 1
        trusted["cargo"] = 1
        trusted["make"] = 1
        trusted["python"] = 1
        trusted["go"] = 1
        trusted["ruby"] = 1
        trusted["java"] = 1
        trusted["gradle"] = 1
        trusted["maven"] = 1
        trusted["pip"] = 1

        # Build excluded dirs lookup
        excluded[0] = "node_modules"
        excluded[1] = ".git"
        excluded[2] = "vendor"
        excluded[3] = "target"
        excluded[4] = ".venv"
        excluded[5] = "venv"
        excluded[6] = "dist"
        excluded[7] = "build"

        # Patterns for excluded dirs (for checking cd arguments)
        excluded_pattern = "^(node_modules|\\.git|vendor|target|\\.venv|venv|dist|build)$"
    }
    {
        # Replace separators with newline for easier processing
        cmd_line = $0
        gsub(/[[:space:]]*&&[[:space:]]*/, "\n", cmd_line)
        gsub(/[[:space:]]*\|\|[[:space:]]*/, "\n", cmd_line)
        gsub(/[[:space:]]*;[[:space:]]*/, "\n", cmd_line)

        # Split into segments
        n = split(cmd_line, segs, "\n")
        for (i = 1; i <= n; i++) {
            segment = segs[i]

            # Trim whitespace
            gsub(/^[[:space:]]+/, "", segment)
            gsub(/[[:space:]]+$/, "", segment)

            if (segment == "") continue

            # Get first word
            first_word = segment
            sub(/[[:space:]]+.*/, "", first_word)

            # Special handling for cd - check if it's navigating to excluded dir
            if (first_word == "cd") {
                # Extract the cd argument
                cd_arg = segment
                sub(/^cd[[:space:]]+/, "", cd_arg)
                # Remove trailing options
                sub(/[[:space:]]+.*/, "", cd_arg)
                # Trim
                gsub(/^[[:space:]]+/, "", cd_arg)
                gsub(/[[:space:]]+$/, "", cd_arg)

                # Check if cd_arg is an excluded directory
                if (match(cd_arg, excluded_pattern)) {
                    print "Blocked: Command contains excluded directory '" cd_arg "'." > "/dev/stderr"
                    exit 2
                }
                # cd with safe argument is allowed
                continue
            }

            # Check if safe or trusted
            is_safe = (first_word in safe || first_word in trusted)

            if (!is_safe) {
                # Check for excluded directories
                for (d = 0; d <= 7; d++) {
                    dir = excluded[d]
                    # Check if dir appears as complete path component
                    if (match(segment, "(^| |/)" dir "( |/|$)")) {
                        print "Blocked: Command contains excluded directory '" dir "'." > "/dev/stderr"
                        exit 2
                    }
                }
            }
        }
    }
AWKEOF

    echo "$cmd" | awk "$awkprog" || return $?

    return 0
}

# Validate the entire command
if ! validate_segments "$CMD"; then
    exit 2
fi

exit 0
