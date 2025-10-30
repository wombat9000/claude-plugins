# Claude Plugin Marketplace

A marketplace for Claude Code agent configuration plugins.

## Overview

This repository provides a plugin marketplace for Claude Code extensions. Users can discover, install, and manage plugins distributed through this marketplace.

## Using This Marketplace

### 1. Add the marketplace to Claude Code

```shell
/plugin marketplace add https://github.com/wombat9000/claude-plugins.git
```

### 2. Browse available plugins

```shell
/plugin
```

### 3. Install plugins from this marketplace

```shell
/plugin install plugin-name@wombat9000-marketplace
```

## Available Plugins

### config-wizard

Interactive wizard to help create and review Claude Code slash commands.

Provides slash commands to initialize new commands and review existing ones. Supports creating commands at project, personal, or plugin level.

**Version**: 1.0.0

**Features:**
- `/config-wizard:cmd-init` - Initialize a new slash command for Claude Code
- `/config-wizard:cmd-review` - Review an existing slash command from the current project
- Interactive prompts to guide command creation
- Support for project, personal, and plugin-level commands

### dependency-blocker

Prevents Claude from accessing dependency directories to save tokens and improve performance.

Blocks access to `node_modules`, `.git`, `dist`, `build`, `vendor`, `target`, `.venv`, and `venv` directories through Bash, Read, Glob, and Grep validation hooks.

**Category**: utilities
**Version**: 1.0.0
**License**: MIT

**Features:**
- Blocks Bash commands targeting excluded directories
- Blocks Read operations from excluded directories
- Blocks Glob patterns targeting excluded directories
- Blocks Grep searches in excluded directories
- Comprehensive test suite with 80 tests

## Team Configuration

For automatic marketplace installation in team projects, add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "wombat9000-marketplace": {
      "source": {
        "source": "github",
        "repo": "wombat9000/claude-plugins"
      }
    }
  }
}
```