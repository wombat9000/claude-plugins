#!/usr/bin/env bats

# Tests for glob-validate.sh

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    SCRIPT="$DIR/../scripts/glob-validate.sh"
    chmod +x "$SCRIPT"
}

# ============================================
# Command-line mode - Pattern - Should Block
# ============================================

@test "blocks pattern **/.env" {
    run "$SCRIPT" "**/.env"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks pattern **/.bashrc" {
    run "$SCRIPT" "**/.bashrc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks pattern .env*" {
    run "$SCRIPT" ".env*"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks pattern .ssh/**" {
    run "$SCRIPT" ".ssh/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks pattern .aws/*" {
    run "$SCRIPT" ".aws/*"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks pattern with .docker" {
    run "$SCRIPT" ".docker/config.json"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command-line mode - Pattern - Should Allow
# ============================================

@test "allows pattern src/**/*.js" {
    run "$SCRIPT" "src/**/*.js"
    [ "$status" -eq 0 ]
}

@test "allows pattern **/*.md" {
    run "$SCRIPT" "**/*.md"
    [ "$status" -eq 0 ]
}

@test "allows pattern config/*.json" {
    run "$SCRIPT" "config/*.json"
    [ "$status" -eq 0 ]
}

@test "allows pattern with 'env' substring" {
    run "$SCRIPT" "environment/**"
    [ "$status" -eq 0 ]
}

# ============================================
# Command-line mode - Path parameter - Should Block
# ============================================

@test "blocks path parameter .ssh" {
    run "$SCRIPT" "*.key" ".ssh"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks path parameter .aws" {
    run "$SCRIPT" "*" ".aws"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command-line mode - Path parameter - Should Allow
# ============================================

@test "allows safe path parameter" {
    run "$SCRIPT" "*.js" "src"
    [ "$status" -eq 0 ]
}

@test "allows path with 'env' substring" {
    run "$SCRIPT" "*.js" "environment"
    [ "$status" -eq 0 ]
}

# ============================================
# JSON mode - Should Block
# ============================================

@test "JSON: blocks pattern .env*" {
    echo '{"tool_input": {"pattern": ".env*"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: blocks pattern **/.bashrc" {
    echo '{"tool_input": {"pattern": "**/.bashrc"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: blocks path .ssh" {
    echo '{"tool_input": {"pattern": "*", "path": ".ssh"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# JSON mode - Should Allow
# ============================================

@test "JSON: allows safe pattern" {
    echo '{"tool_input": {"pattern": "src/**/*.js"}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "JSON: allows safe path" {
    echo '{"tool_input": {"pattern": "*.md", "path": "docs"}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge Cases
# ============================================

@test "handles empty pattern gracefully" {
    run "$SCRIPT" ""
    [ "$status" -eq 0 ]
}

@test "handles JSON with missing pattern" {
    echo '{"tool_input": {}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "handles malformed JSON gracefully" {
    echo 'invalid json' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}
