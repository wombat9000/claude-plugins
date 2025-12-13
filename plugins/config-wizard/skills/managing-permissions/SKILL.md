---
name: managing-permissions
description: Guide for configuring Claude Code permissions in settings.json with security best practices for allow, ask, and deny rules. Use when: (1) Setting up or modifying permissions in settings.json, (2) Discussing tool permissions, access control, or security configuration, (3) User mentions allowing, blocking, or restricting specific tools or file access, (4) Configuring Bash command permissions, file access (Read/Edit/Write), or WebFetch restrictions, (5) Questions about what permissions are safe vs risky, (6) Troubleshooting permission-related errors or "permission denied" issues, (7) Reviewing security configuration or hardening Claude Code access.
---

# Managing Permissions

Configure Claude Code permissions to control tool access and protect sensitive files.

## Overview

Permissions are configured in `settings.json` using three groups: **allow**, **ask**, and **deny**.

**Rule precedence**: Deny > Ask > Allow

**Configuration hierarchy** (highest to lowest):
1. Managed settings (enterprise policies)
2. Command-line arguments
3. Local project settings (`.claude/settings.local.json`)
4. Shared project settings (`.claude/settings.json`)
5. User global settings (`~/.claude/settings.json`)

## Permission Groups

### Allow

Grants explicit permission for tool use without confirmation.

**When to use:** Safe, routine operations that don't risk data loss or security exposure.

**Examples:** Reading source code, running tests, read-only git commands.

See **[references/allow-permissions.md](references/allow-permissions.md)** for comprehensive safe patterns and project templates.

### Ask

Prompts for user confirmation before allowing tool use.

**When to use:** Operations requiring review, such as publishing changes or modifying dependencies.

**Examples:** Git push/commit, package installation, editing critical config files.

See **[references/ask-permissions.md](references/ask-permissions.md)** for recommended patterns and balancing security with convenience.

### Deny

Explicitly blocks tool use. Takes precedence over allow and ask rules.

**When to use:** Protecting sensitive files, blocking dangerous commands, preventing network access.

**Examples:** Environment files, cloud credentials, dangerous commands, network access.

See **[references/deny-permissions.md](references/deny-permissions.md)** for critical security patterns and baseline template.

## Basic Syntax

All permission rules follow this format:

```
ToolName(pattern)
```

**Available Tools:** Bash, Read, Edit, Write, WebFetch, NotebookEdit

**Pattern types:**
- **Bash**: Prefix matching - `Bash(git status)` matches "git status", "git status file.txt"
- **File tools**: Glob matching - `Read(src/**)` matches all files in src/ recursively

**Important:** Bash patterns can be bypassed with command chaining. Always combine Bash restrictions with file-level deny patterns for security.

See **[references/official-reference.md](references/official-reference.md)** for complete syntax reference and known limitations.

## Configuration Workflow

When setting up permissions:

1. **Start with deny rules** - Block sensitive files and dangerous commands (see deny-permissions.md for baseline template)
2. **Add allow rules** - Enable routine safe operations
3. **Add ask rules** - Require confirmation for important operations
4. **Test configuration** - Verify typical workflows work correctly
5. **Iterate** - Add rules as needed based on actual usage

## Getting Started

Minimal secure configuration:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(**/.env)",
      "Read(~/.aws/**)",
      "Read(~/.ssh/**)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ],
    "allow": [
      "Bash(npm run test:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Read(src/**)",
      "Read(tests/**)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Bash(npm install:*)"
    ]
  }
}
```

## Reference Files

For detailed guidance, patterns, and security best practices:

- **[references/deny-permissions.md](references/deny-permissions.md)** - Critical security patterns, baseline template, bypass prevention (START HERE for security)
- **[references/allow-permissions.md](references/allow-permissions.md)** - Safe patterns, project templates, anti-patterns to avoid
- **[references/ask-permissions.md](references/ask-permissions.md)** - When to require confirmation, common patterns
- **[references/official-reference.md](references/official-reference.md)** - Complete technical reference, glob syntax, known limitations
