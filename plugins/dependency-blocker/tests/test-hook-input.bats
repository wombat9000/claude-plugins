#!/usr/bin/env bats

# Tests for hook scripts receiving JSON input via stdin (as Claude Code provides)

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    HOOKS_DIR="$DIR/../scripts"

    chmod +x "$HOOKS_DIR/bash-validate.sh"
    chmod +x "$HOOKS_DIR/read-validate.sh"
}

# ============================================
# Test JSON input format (as Claude Code sends it)
# ============================================

@test "bash-validate: receives JSON via stdin and blocks node_modules" {
    # Simulate the JSON input that Claude Code sends to PreToolUse hooks
    local json_input='{
  "session_id": "test123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls node_modules"
  }
}'

    run bash -c "echo '$json_input' | '$HOOKS_DIR/bash-validate.sh'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "read-validate: receives JSON via stdin and blocks node_modules" {
    # Simulate the JSON input that Claude Code sends to PreToolUse hooks
    local json_input='{
  "session_id": "test123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "node_modules/package/index.js"
  }
}'

    run bash -c "echo '$json_input' | '$HOOKS_DIR/read-validate.sh'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "bash-validate: allows safe commands via JSON input" {
    local json_input='{
  "session_id": "test123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls src"
  }
}'

    run bash -c "echo '$json_input' | '$HOOKS_DIR/bash-validate.sh'"
    [ "$status" -eq 0 ]
}

@test "read-validate: allows safe file paths via JSON input" {
    local json_input='{
  "session_id": "test123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "src/index.js"
  }
}'

    run bash -c "echo '$json_input' | '$HOOKS_DIR/read-validate.sh'"
    [ "$status" -eq 0 ]
}
