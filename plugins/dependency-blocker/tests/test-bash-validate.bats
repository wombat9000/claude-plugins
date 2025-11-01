#!/usr/bin/env bats

# Tests for bash-validate.sh

# ============================================
# Setup
# ============================================

setup_file() {
    # Run once before all tests
    export TEST_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    export SCRIPT="$TEST_DIR/../scripts/bash-validate.sh"
    chmod +x "$SCRIPT"
}

setup() {
    # Load shared test helpers
    load test_helper
}

# ============================================
# Tests: Blocked Commands - Direct Access
# ============================================

@test "blocks ls on excluded directories" {
    local -a commands=(
        "ls node_modules"
        "ls vendor"
        "ls dist"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

@test "blocks find in excluded directories" {
    local -a commands=(
        "find node_modules -name '*.js'"
        "find target -type f"
        "find build -name '*.o'"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

@test "blocks cat from excluded directories" {
    local -a commands=(
        "cat .git/config"
        "cat .venv/bin/activate"
        "cat dist/bundle.js"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

@test "blocks grep in excluded directories" {
    local -a commands=(
        "grep -r 'test' dist/"
        "grep -r 'import' venv/"
        "grep 'error' dist/app.js"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

@test "blocks cd to excluded directories" {
    test_bash_command "cd build && ls"
    assert_blocked
}

@test "blocks access to nested excluded directory paths" {
    local -a commands=(
        "cat src/node_modules/package.json"
        "cat project/vendor/package.json"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

# ============================================
# Tests: Allowed Commands - Safe Operations
# ============================================

@test "allows operations on safe directories" {
    local -a commands=(
        "ls src"
        "find src -name '*.js'"
        "grep -r 'test' src/"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

@test "allows general safe commands" {
    local -a commands=(
        "/usr/bin/git status"
        "echo 'hello world'"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

# ============================================
# Tests: Trusted Tool Invocations
# ============================================

@test "allows npm commands" {
    local -a commands=(
        "npm install"
        "npm run build"
        "npm run dev"
        "npm ci"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

@test "allows yarn commands" {
    local -a commands=(
        "yarn install"
        "yarn build"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

@test "allows other package managers" {
    local -a commands=(
        "pnpm install"
        "cargo build"
        "cargo test"
        "make build"
        "python -m pip install"
        "go build"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

# ============================================
# Tests: Command Chains - Safe Combinations
# ============================================

@test "allows safe navigation with tool invocations" {
    local -a commands=(
        "cd /path && npm run build"
        "pwd && npm install"
        "pushd /path && cargo build"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

@test "allows multiple tool invocations chained together" {
    local -a commands=(
        "npm install && npm run build"
        "cd /path && npm install && npm run build"
        "npm install && pwd"
        "cd /a && pushd /b && npm build && popd"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_allowed || {
            echo "Failed to allow: $cmd" >&2
            return 1
        }
    done
}

# ============================================
# Tests: Command Chains - Blocked Combinations
# ============================================

@test "blocks excluded directory access after tool invocation" {
    local -a commands=(
        "npm run build && grep secret dist/app.js"
        "npm run build ; grep -r error build/"
        "make build || find dist -name '*.js'"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

@test "blocks excluded directory access before tool invocation" {
    test_bash_command "cat node_modules/file && npm run build"
    assert_blocked
}

@test "blocks excluded directory access in middle of chain" {
    local -a commands=(
        "cd /path && cat node_modules/pkg && npm run build"
        "npm install && ls node_modules && npm run build"
    )

    for cmd in "${commands[@]}"; do
        test_bash_command "$cmd"
        assert_blocked || {
            echo "Failed to block: $cmd" >&2
            return 1
        }
    done
}

# ============================================
# Tests: Edge Cases
# ============================================

@test "allows commands with similar names to excluded dirs" {
    # Should allow "node_module" (without 's')
    test_bash_command "ls node_module"
    assert_allowed
}

@test "blocks exact match of excluded directory names" {
    # Should block exact "dist"
    test_bash_command "ls dist"
    assert_blocked
}

# ============================================
# Tests: JSON/Hook Mode
# ============================================

@test "JSON mode: blocks excluded directory commands" {
    local -a commands=(
        "ls node_modules"
        "cat dist/file.js"
        "npm run build && grep secret dist/app.js"
    )

    for cmd in "${commands[@]}"; do
        test_bash_json_command "$cmd"
        assert_blocked || {
            echo "Failed to block JSON command: $cmd" >&2
            return 1
        }
    done
}

@test "JSON mode: allows safe and tool commands" {
    local -a commands=(
        "ls src"
        "npm run build"
        "cd /path && npm run build"
    )

    for cmd in "${commands[@]}"; do
        test_bash_json_command "$cmd"
        assert_allowed || {
            echo "Failed to allow JSON command: $cmd" >&2
            return 1
        }
    done
}