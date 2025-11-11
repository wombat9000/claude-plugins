#!/bin/bash

# This script provides context to Claude at session start about the block-dotfiles plugin.
# It informs Claude proactively about sensitive files that are blocked for security reasons.

cat <<'EOF'
SECURITY: DOTFILES BLOCKED

Sensitive files are BLOCKED for security (credentials/API keys):

Shell configs: .bashrc, .zshrc, .bash_profile, .zsh_profile, .profile
Environment files: .env, .env.local, .env.production, .env.development, .env.staging, .env.test
Credential stores: .ssh/, .aws/, .npmrc, .pypirc, .gitconfig, .netrc, .docker/, .dockercfg, .kube/, .config/gcloud/

DO NOT attempt to read, grep, glob, or access these files.
They contain credentials and secrets that must not be exposed.

If you need environment configuration, ask the user to provide it explicitly.
EOF
