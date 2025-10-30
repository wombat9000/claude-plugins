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

@test "blocks read from .bashrc" {
    run "$SCRIPT" ".bashrc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .zshrc" {
    run "$SCRIPT" ".zshrc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .env" {
    run "$SCRIPT" ".env"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .env.local" {
    run "$SCRIPT" ".env.local"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .env.production" {
    run "$SCRIPT" ".env.production"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .ssh directory" {
    run "$SCRIPT" ".ssh/id_rsa"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .aws directory" {
    run "$SCRIPT" ".aws/credentials"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .npmrc" {
    run "$SCRIPT" ".npmrc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .gitconfig" {
    run "$SCRIPT" ".gitconfig"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks read from .docker directory" {
    run "$SCRIPT" ".docker/config.json"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks nested .env path" {
    run "$SCRIPT" "/home/user/project/.env"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks .bashrc in absolute path" {
    run "$SCRIPT" "/home/user/.bashrc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "blocks .ssh in nested path" {
    run "$SCRIPT" "/home/user/.ssh/id_rsa"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# Command-line mode - Should Allow
# ============================================

@test "allows read from regular file" {
    run "$SCRIPT" "src/index.js"
    [ "$status" -eq 0 ]
}

@test "allows read from README.md" {
    run "$SCRIPT" "README.md"
    [ "$status" -eq 0 ]
}

@test "allows read from config directory" {
    run "$SCRIPT" "config/app.json"
    [ "$status" -eq 0 ]
}

@test "allows path containing 'env' but not '.env'" {
    run "$SCRIPT" "environment/config.js"
    [ "$status" -eq 0 ]
}

@test "allows path containing 'ssh' but not '.ssh'" {
    run "$SCRIPT" "src/ssh-client.js"
    [ "$status" -eq 0 ]
}

@test "allows path with .envrc (different file)" {
    run "$SCRIPT" ".envrc"
    [ "$status" -eq 0 ]
}

# ============================================
# JSON mode - Should Block
# ============================================

@test "JSON: blocks read from .env" {
    echo '{"tool_input": {"file_path": ".env"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: blocks read from .bashrc" {
    echo '{"tool_input": {"file_path": "/home/user/.bashrc"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

@test "JSON: blocks read from .ssh directory" {
    echo '{"tool_input": {"file_path": ".ssh/id_rsa"}}' | run "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Blocked" ]]
}

# ============================================
# JSON mode - Should Allow
# ============================================

@test "JSON: allows read from regular file" {
    echo '{"tool_input": {"file_path": "src/index.js"}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "JSON: allows read from package.json" {
    echo '{"tool_input": {"file_path": "package.json"}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================
# Edge Cases
# ============================================

@test "handles empty input gracefully" {
    run "$SCRIPT" ""
    [ "$status" -eq 0 ]
}

@test "handles JSON with missing file_path" {
    echo '{"tool_input": {}}' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "handles malformed JSON gracefully" {
    echo 'invalid json' | run "$SCRIPT"
    [ "$status" -eq 0 ]
}
