---
description: Initialize a new slash command for Claude Code.
args:
  - name: name
    description: Name of the command to create (without leading slash)
    required: true
  - name: location
    description: Where to create the command (project, personal, or plugin)
    required: false
    default: project
  - name: plugin
    description: Plugin name (required if location=plugin)
    required: false
---

# Command Initialization

Parse the arguments:
- `name` - The command name (e.g., "hello" creates "/hello")
- `location` - Where to create: "project", "personal", or "plugin" (default: "project")
- `plugin` - Plugin name (only needed if location="plugin")

Create the command file in the appropriate location:
- **project**: `.claude/commands/{name}.md` in current project
- **personal**: `~/.claude/commands/{name}.md` in user home
- **plugin**: `.claude-plugin/commands/{name}.md` in specified plugin

The command file should contain a basic template with frontmatter (description) and a placeholder prompt.
