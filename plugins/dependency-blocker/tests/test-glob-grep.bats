#!/usr/bin/env bats

# Tests for Glob and Grep validation hooks

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    HOOKS_DIR="$DIR/../scripts"

    chmod +x "$HOOKS_DIR/glob-validate.sh"
    chmod +x "$HOOKS_DIR/grep-validate.sh"
}

# ============================================
# Glob validation - Should Block
# ============================================

@test "glob-validate: blocks node_modules/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "node_modules/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks node_modules/* pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "node_modules/*"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks **/node_modules/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "**/node_modules/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks .git/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" ".git/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks vendor/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "vendor/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks target/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "target/**"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks dist/*.js pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "dist/*.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks build/**/*.js pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "build/**/*.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "glob-validate: blocks with path in node_modules" {
    run "$HOOKS_DIR/glob-validate.sh" "*.js" "node_modules/react"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Glob validation - Should Allow
# ============================================

@test "glob-validate: allows src/** pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "src/**"
    [ "$status" -eq 0 ]
}

@test "glob-validate: allows **/*.js pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "**/*.js"
    [ "$status" -eq 0 ]
}

@test "glob-validate: allows lib/**/*.ts pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "lib/**/*.ts"
    [ "$status" -eq 0 ]
}

@test "glob-validate: allows *.json pattern" {
    run "$HOOKS_DIR/glob-validate.sh" "*.json"
    [ "$status" -eq 0 ]
}

@test "glob-validate: allows with safe path" {
    run "$HOOKS_DIR/glob-validate.sh" "*.js" "src"
    [ "$status" -eq 0 ]
}

# ============================================
# Grep validation - Should Block
# ============================================

@test "grep-validate: blocks search in node_modules" {
    run "$HOOKS_DIR/grep-validate.sh" "node_modules"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in node_modules/" {
    run "$HOOKS_DIR/grep-validate.sh" "node_modules/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in node_modules/package" {
    run "$HOOKS_DIR/grep-validate.sh" "node_modules/package"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in .git" {
    run "$HOOKS_DIR/grep-validate.sh" ".git"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in vendor" {
    run "$HOOKS_DIR/grep-validate.sh" "vendor"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in target" {
    run "$HOOKS_DIR/grep-validate.sh" "target"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in dist" {
    run "$HOOKS_DIR/grep-validate.sh" "dist"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in build/" {
    run "$HOOKS_DIR/grep-validate.sh" "build/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in .venv" {
    run "$HOOKS_DIR/grep-validate.sh" ".venv"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks search in venv" {
    run "$HOOKS_DIR/grep-validate.sh" "venv"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "grep-validate: blocks absolute path to node_modules" {
    run "$HOOKS_DIR/grep-validate.sh" "/home/user/project/node_modules"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Grep validation - Should Allow
# ============================================

@test "grep-validate: allows search in src" {
    run "$HOOKS_DIR/grep-validate.sh" "src"
    [ "$status" -eq 0 ]
}

@test "grep-validate: allows search in lib" {
    run "$HOOKS_DIR/grep-validate.sh" "lib"
    [ "$status" -eq 0 ]
}

@test "grep-validate: allows search in test" {
    run "$HOOKS_DIR/grep-validate.sh" "test"
    [ "$status" -eq 0 ]
}

@test "grep-validate: allows search in current directory (empty path)" {
    run "$HOOKS_DIR/grep-validate.sh" ""
    [ "$status" -eq 0 ]
}

@test "grep-validate: allows search in src/components" {
    run "$HOOKS_DIR/grep-validate.sh" "src/components"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge cases
# ============================================

@test "glob edge case: allows builds.ts (not build/)" {
    run "$HOOKS_DIR/glob-validate.sh" "src/builds.ts"
    [ "$status" -eq 0 ]
}

@test "glob edge case: blocks build/ directory" {
    run "$HOOKS_DIR/glob-validate.sh" "build/*"
    [ "$status" -eq 2 ]
}

@test "grep edge case: allows distribution.js path" {
    run "$HOOKS_DIR/grep-validate.sh" "src/distribution.js"
    [ "$status" -eq 0 ]
}

@test "grep edge case: blocks dist directory" {
    run "$HOOKS_DIR/grep-validate.sh" "dist"
    [ "$status" -eq 2 ]
}
