#!/usr/bin/env bats

# Tests for read-validate.sh

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    SCRIPT="$DIR/../scripts/read-validate.sh"
    chmod +x "$SCRIPT"
}

# ============================================
# Command-line mode - Should Block
# ============================================

@test "blocks read from node_modules" {
    run "$SCRIPT" "node_modules/package/index.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .git" {
    run "$SCRIPT" ".git/config"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from dist" {
    run "$SCRIPT" "dist/bundle.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from build" {
    run "$SCRIPT" "build/output.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks nested node_modules path" {
    run "$SCRIPT" "/path/to/node_modules/pkg/file.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks .git in absolute path" {
    run "$SCRIPT" "/home/user/project/.git/HEAD"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from vendor" {
    run "$SCRIPT" "vendor/autoload.php"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from target" {
    run "$SCRIPT" "target/release/binary"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .venv" {
    run "$SCRIPT" ".venv/lib/python3.11/site-packages/module.py"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from venv" {
    run "$SCRIPT" "venv/bin/activate"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command-line mode - Should Allow
# ============================================

@test "allows read from src" {
    run "$SCRIPT" "src/index.js"
    [ "$status" -eq 0 ]
}

@test "allows read from root" {
    run "$SCRIPT" "package.json"
    [ "$status" -eq 0 ]
}

@test "allows read from lib" {
    run "$SCRIPT" "lib/utils.js"
    [ "$status" -eq 0 ]
}

@test "allows read from test directory" {
    run "$SCRIPT" "test/unit/test.js"
    [ "$status" -eq 0 ]
}

@test "allows read config files" {
    run "$SCRIPT" "tsconfig.json"
    [ "$status" -eq 0 ]
}

@test "allows read markdown" {
    run "$SCRIPT" "README.md"
    [ "$status" -eq 0 ]
}

# ============================================
# JSON input mode
# ============================================

@test "JSON: blocks node_modules file" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "node_modules/package/index.js"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: allows safe file path" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "src/index.js"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge cases
# ============================================

@test "edge case: allows builds (with s)" {
    run "$SCRIPT" "src/builds.ts"
    [ "$status" -eq 0 ]
}

@test "edge case: allows .gitignore file" {
    run "$SCRIPT" ".gitignore"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks .git directory object" {
    run "$SCRIPT" ".git/objects/abc123"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "edge case: allows distribution.js (not dist/)" {
    run "$SCRIPT" "src/distribution.js"
    [ "$status" -eq 0 ]
}

@test "edge case: allows targeted.rs (not target/)" {
    run "$SCRIPT" "src/targeted.rs"
    [ "$status" -eq 0 ]
}

@test "edge case: allows vendor.js (not vendor/)" {
    run "$SCRIPT" "src/vendor.js"
    [ "$status" -eq 0 ]
}

@test "edge case: allows environment.py (not venv/)" {
    run "$SCRIPT" "src/environment.py"
    [ "$status" -eq 0 ]
}
