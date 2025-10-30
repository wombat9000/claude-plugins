#!/usr/bin/env bats

# Tests for glob-validate.sh

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    SCRIPT="$DIR/../scripts/glob-validate.sh"
    chmod +x "$SCRIPT"
}

# ============================================
# Should Block
# ============================================

@test "blocks node_modules/** pattern" {
    run "$SCRIPT" "node_modules/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks node_modules/* pattern" {
    run "$SCRIPT" "node_modules/*"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks **/node_modules/** pattern" {
    run "$SCRIPT" "**/node_modules/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks .git/** pattern" {
    run "$SCRIPT" ".git/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks vendor/** pattern" {
    run "$SCRIPT" "vendor/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks target/** pattern" {
    run "$SCRIPT" "target/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks dist/*.js pattern" {
    run "$SCRIPT" "dist/*.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks build/**/*.js pattern" {
    run "$SCRIPT" "build/**/*.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks with path in node_modules" {
    run "$SCRIPT" "*.js" "node_modules/react"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Should Allow
# ============================================

@test "allows src/** pattern" {
    run "$SCRIPT" "src/**"
    [ "$status" -eq 0 ]
}

@test "allows **/*.js pattern" {
    run "$SCRIPT" "**/*.js"
    [ "$status" -eq 0 ]
}

@test "allows lib/**/*.ts pattern" {
    run "$SCRIPT" "lib/**/*.ts"
    [ "$status" -eq 0 ]
}

@test "allows *.json pattern" {
    run "$SCRIPT" "*.json"
    [ "$status" -eq 0 ]
}

@test "allows with safe path" {
    run "$SCRIPT" "*.js" "src"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge cases
# ============================================

@test "edge case: allows builds.ts (not build/)" {
    run "$SCRIPT" "src/builds.ts"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks build/ directory" {
    run "$SCRIPT" "build/*"
    [ "$status" -eq 2 ]
}
