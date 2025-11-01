#!/usr/bin/env bats

# Tests for bash-validate.sh

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    SCRIPT="$DIR/../scripts/bash-validate.sh"
    chmod +x "$SCRIPT"
}

# ============================================
# Command-line mode - Should Block
# ============================================

@test "blocks ls node_modules" {
    run "$SCRIPT" "ls node_modules"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks find in node_modules" {
    run "$SCRIPT" "find node_modules -name '*.js'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks cat from .git" {
    run "$SCRIPT" "cat .git/config"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks grep in dist" {
    run "$SCRIPT" "grep -r 'test' dist/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks cd to build" {
    run "$SCRIPT" "cd build && ls"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks node_modules in nested path" {
    run "$SCRIPT" "cat src/node_modules/package.json"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks ls vendor" {
    run "$SCRIPT" "ls vendor"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks find in target" {
    run "$SCRIPT" "find target -type f"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks cat from .venv" {
    run "$SCRIPT" "cat .venv/bin/activate"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks grep in venv" {
    run "$SCRIPT" "grep -r 'import' venv/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command-line mode - Should Allow
# ============================================

@test "allows ls src" {
    run "$SCRIPT" "ls src"
    [ "$status" -eq 0 ]
}

@test "allows find in src" {
    run "$SCRIPT" "find src -name '*.js'"
    [ "$status" -eq 0 ]
}

@test "allows git status command" {
    run "$SCRIPT" "/usr/bin/git status"
    [ "$status" -eq 0 ]
}

@test "allows npm install" {
    run "$SCRIPT" "npm install"
    [ "$status" -eq 0 ]
}

@test "allows grep in src" {
    run "$SCRIPT" "grep -r 'test' src/"
    [ "$status" -eq 0 ]
}

@test "allows general echo command" {
    run "$SCRIPT" "echo 'hello world'"
    [ "$status" -eq 0 ]
}

# ============================================
# JSON input mode
# ============================================

@test "JSON: blocks node_modules command" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls node_modules"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: allows safe command" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls src"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge cases
# ============================================

@test "edge case: allows node_module without s" {
    run "$SCRIPT" "ls node_module"
    [ "$status" -eq 0 ]
}

@test "edge case: blocks exact dist directory" {
    run "$SCRIPT" "ls dist"
    [ "$status" -eq 2 ]
}

@test "edge case: blocks nested vendor path" {
    run "$SCRIPT" "cat project/vendor/package.json"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Tool invocations - Should Allow
# ============================================

@test "allows npm run build" {
    run "$SCRIPT" "npm run build"
    [ "$status" -eq 0 ]
}

@test "allows npm run dev" {
    run "$SCRIPT" "npm run dev"
    [ "$status" -eq 0 ]
}

@test "allows npm ci" {
    run "$SCRIPT" "npm ci"
    [ "$status" -eq 0 ]
}

@test "allows yarn install" {
    run "$SCRIPT" "yarn install"
    [ "$status" -eq 0 ]
}

@test "allows yarn build" {
    run "$SCRIPT" "yarn build"
    [ "$status" -eq 0 ]
}

@test "allows pnpm install" {
    run "$SCRIPT" "pnpm install"
    [ "$status" -eq 0 ]
}

@test "allows cargo build" {
    run "$SCRIPT" "cargo build"
    [ "$status" -eq 0 ]
}

@test "allows cargo test" {
    run "$SCRIPT" "cargo test"
    [ "$status" -eq 0 ]
}

@test "allows make build" {
    run "$SCRIPT" "make build"
    [ "$status" -eq 0 ]
}

@test "allows python -m pip install" {
    run "$SCRIPT" "python -m pip install"
    [ "$status" -eq 0 ]
}

@test "allows go build" {
    run "$SCRIPT" "go build"
    [ "$status" -eq 0 ]
}

@test "blocks cat dist file" {
    run "$SCRIPT" "cat dist/bundle.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks grep in dist file" {
    run "$SCRIPT" "grep 'error' dist/app.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks find in build" {
    run "$SCRIPT" "find build -name '*.o'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: allows npm run build" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm run build"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 0 ]
}

@test "JSON: blocks cat dist file" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "cat dist/file.js"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command segments - complex chains
# ============================================

@test "allows cd then npm run build" {
    run "$SCRIPT" "cd /path && npm run build"
    [ "$status" -eq 0 ]
}

@test "allows pwd then npm install" {
    run "$SCRIPT" "pwd && npm install"
    [ "$status" -eq 0 ]
}

@test "allows pushd then cargo build" {
    run "$SCRIPT" "pushd /path && cargo build"
    [ "$status" -eq 0 ]
}

@test "allows multiple tool invocations" {
    run "$SCRIPT" "npm install && npm run build"
    [ "$status" -eq 0 ]
}

@test "allows cd with multiple tools" {
    run "$SCRIPT" "cd /path && npm install && npm run build"
    [ "$status" -eq 0 ]
}

@test "blocks npm run build then grep in dist" {
    run "$SCRIPT" "npm run build && grep secret dist/app.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks cat then npm run build" {
    run "$SCRIPT" "cat node_modules/file && npm run build"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks grep in build after npm" {
    run "$SCRIPT" "npm run build ; grep -r error build/"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks find in dist after make" {
    run "$SCRIPT" "make build || find dist -name '*.js'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "allows tool then safe command" {
    run "$SCRIPT" "npm install && pwd"
    [ "$status" -eq 0 ]
}

@test "blocks dangerous command in middle of chain" {
    run "$SCRIPT" "cd /path && cat node_modules/pkg && npm run build"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "allows multiple safe navigation commands" {
    run "$SCRIPT" "cd /a && pushd /b && npm build && popd"
    [ "$status" -eq 0 ]
}

@test "blocks ls node_modules in middle of chain" {
    run "$SCRIPT" "npm install && ls node_modules && npm run build"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: blocks npm run build then grep in dist" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm run build && grep secret dist/app.js"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: allows cd then npm run build" {
    local json='{
  "session_id": "test",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "cd /path && npm run build"
  }
}'
    run bash -c "echo '$json' | '$SCRIPT'"
    [ "$status" -eq 0 ]
}
