#!/bin/bash

# This script provides context to Claude at session start about the dependency blocker plugin.
# It informs Claude proactively about blocked directories and allowed tools.

cat <<'EOF'
DEPENDENCY BLOCKER PLUGIN ACTIVE

Blocked Directories (DO NOT use Read/Glob/Grep/file access commands on these):
- node_modules, .git, vendor, target, .venv, venv, dist, build

Allowed Tools (these CAN operate on blocked directories):
- npm, yarn, pnpm, cargo, make, pip, go, ruby, java, gradle, maven, python

Rationale: These directories contain 100k+ generated/dependency files that waste tokens.

Recommended approach: Use package manager commands instead of file access commands.
EOF
