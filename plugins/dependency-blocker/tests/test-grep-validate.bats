#!/usr/bin/env bats

# Tests for grep-validate.sh

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    SCRIPT="$DIR/../scripts/grep-validate.sh"
    chmod +x "$SCRIPT"
}

# ============================================
# Should Block
# ============================================

@test "blocks search in node_modules" {
    run "$SCRIPT" "node_modules"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in node_modules/" {
    run "$SCRIPT" "node_modules/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in node_modules/package" {
    run "$SCRIPT" "node_modules/package"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in .git" {
    run "$SCRIPT" ".git"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in vendor" {
    run "$SCRIPT" "vendor"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in target" {
    run "$SCRIPT" "target"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in dist" {
    run "$SCRIPT" "dist"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in build/" {
    run "$SCRIPT" "build/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in .venv" {
    run "$SCRIPT" ".venv"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks search in venv" {
    run "$SCRIPT" "venv"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks absolute path to node_modules" {
    run "$SCRIPT" "/home/user/project/node_modules"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Should Allow
# ============================================

@test "allows search in src" {
    run "$SCRIPT" "src"
    [ "$status" -eq 0 ]
}

@test "allows search in lib" {
    run "$SCRIPT" "lib"
    [ "$status" -eq 0 ]
}

@test "allows search in test" {
    run "$SCRIPT" "test"
    [ "$status" -eq 0 ]
}

@test "allows search in current directory (empty path)" {
    run "$SCRIPT" ""
    [ "$status" -eq 0 ]
}

@test "allows search in src/components" {
    run "$SCRIPT" "src/components"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge cases
# ============================================

@test "edge case: allows distribution.js path" {
    run "$SCRIPT" "src/distribution.js"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks dist directory" {
    run "$SCRIPT" "dist"
    [ "$status" -eq 2 ]
}
