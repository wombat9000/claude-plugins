#!/usr/bin/env bats

# BATS tests for dependency-blocker validation hooks
# Run with: bats tests/test-hooks.bats

# Setup - runs before each test
setup() {
    # Get the directory containing the test file
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # Path to hooks directory
    HOOKS_DIR="$DIR/../hooks"

    # Ensure hooks are executable
    chmod +x "$HOOKS_DIR/bash-validate.sh"
    chmod +x "$HOOKS_DIR/read-validate.sh"
}

# ============================================
# bash-validate.sh - Should Block
# ============================================

@test "bash-validate: blocks ls node_modules" {
    run "$HOOKS_DIR/bash-validate.sh" "ls node_modules"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: blocks find in node_modules" {
    run "$HOOKS_DIR/bash-validate.sh" "find node_modules -name '*.js'"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: blocks cat from .git" {
    run "$HOOKS_DIR/bash-validate.sh" "cat .git/config"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: blocks grep in dist" {
    run "$HOOKS_DIR/bash-validate.sh" "grep -r 'test' dist/"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: blocks cd to build" {
    run "$HOOKS_DIR/bash-validate.sh" "cd build && ls"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: blocks node_modules in nested path" {
    run "$HOOKS_DIR/bash-validate.sh" "cat src/node_modules/package.json"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# bash-validate.sh - Should Allow
# ============================================

@test "bash-validate: allows ls src" {
    run "$HOOKS_DIR/bash-validate.sh" "ls src"
    [ "$status" -eq 0 ]
}

@test "bash-validate: allows find in src" {
    run "$HOOKS_DIR/bash-validate.sh" "find src -name '*.js'"
    [ "$status" -eq 0 ]
}

@test "bash-validate: allows git status command" {
    run "$HOOKS_DIR/bash-validate.sh" "/usr/bin/git status"
    [ "$status" -eq 0 ]
}

@test "bash-validate: allows npm install" {
    run "$HOOKS_DIR/bash-validate.sh" "npm install"
    [ "$status" -eq 0 ]
}

@test "bash-validate: allows grep in src" {
    run "$HOOKS_DIR/bash-validate.sh" "grep -r 'test' src/"
    [ "$status" -eq 0 ]
}

@test "bash-validate: allows general echo command" {
    run "$HOOKS_DIR/bash-validate.sh" "echo 'hello world'"
    [ "$status" -eq 0 ]
}

# ============================================
# read-validate.sh - Should Block
# ============================================

@test "read-validate: blocks read from node_modules" {
    run "$HOOKS_DIR/read-validate.sh" "node_modules/package/index.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: blocks read from .git" {
    run "$HOOKS_DIR/read-validate.sh" ".git/config"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: blocks read from dist" {
    run "$HOOKS_DIR/read-validate.sh" "dist/bundle.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: blocks read from build" {
    run "$HOOKS_DIR/read-validate.sh" "build/output.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: blocks nested node_modules path" {
    run "$HOOKS_DIR/read-validate.sh" "/path/to/node_modules/pkg/file.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: blocks .git in absolute path" {
    run "$HOOKS_DIR/read-validate.sh" "/home/user/project/.git/HEAD"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# read-validate.sh - Should Allow
# ============================================

@test "read-validate: allows read from src" {
    run "$HOOKS_DIR/read-validate.sh" "src/index.js"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows read from root" {
    run "$HOOKS_DIR/read-validate.sh" "package.json"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows read from lib" {
    run "$HOOKS_DIR/read-validate.sh" "lib/utils.js"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows read from test directory" {
    run "$HOOKS_DIR/read-validate.sh" "test/unit/test.js"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows read config files" {
    run "$HOOKS_DIR/read-validate.sh" "tsconfig.json"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows read markdown" {
    run "$HOOKS_DIR/read-validate.sh" "README.md"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge Cases
# ============================================

@test "edge case: allows node_module without s" {
    run "$HOOKS_DIR/bash-validate.sh" "ls node_module"
    [ "$status" -eq 0 ]
}

@test "edge case: allows builds (with s)" {
    run "$HOOKS_DIR/read-validate.sh" "src/builds.ts"
    [ "$status" -eq 0 ]
}

@test "edge case: allows .gitignore file" {
    run "$HOOKS_DIR/read-validate.sh" ".gitignore"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks .git directory object" {
    run "$HOOKS_DIR/read-validate.sh" ".git/objects/abc123"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "edge case: allows distribution.js (not dist/)" {
    run "$HOOKS_DIR/read-validate.sh" "src/distribution.js"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks exact dist directory" {
    run "$HOOKS_DIR/bash-validate.sh" "ls dist"
    [ "$status" -eq 1 ]
}
