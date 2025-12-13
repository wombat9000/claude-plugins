# Deny Permissions - Workflow Controls and Limitations

Deny rules block specific tool operations and take precedence over allow rules. They are designed for **workflow control and resource management**, not security.

## Table of Contents

- [Understanding Deny Rules](#understanding-deny-rules)
- [Critical Limitations](#critical-limitations)
- [What Deny Rules ARE Good For](#what-deny-rules-are-good-for)
- [Common Misconceptions](#common-misconceptions)
- [Pattern Examples](#pattern-examples)
- [For Security: Use Hooks Instead](#for-security-use-hooks-instead)
- [Debugging Deny Rules](#debugging-deny-rules)

## Understanding Deny Rules

### What They Are

Deny rules are **workflow controls** that:
- Prevent Claude from using specific tools or accessing specific resources
- Answer the question "When should Claude stop and ask me?"
- Help manage token costs by blocking large or irrelevant files
- Provide guardrails for destructive operations

**Deny rules are NOT security mechanisms.** They have significant limitations that make them unsuitable for protecting secrets or credentials.

### Precedence

When an operation matches multiple rules:

**Deny > Ask > Allow**

However, configuration source hierarchy also matters (managed settings, workspace settings, user settings, etc.). A deny rule from a higher-priority source wins.

### Basic Syntax

```json
{
  "permissions": {
    "deny": [
      "Read(node_modules/**)",           // Block reading dependencies
      "Bash(git push origin main:*)",    // Block pushing to main branch
      "Grep(build/**)"                   // Block searching build artifacts
    ]
  }
}
```

## Critical Limitations

### ⚠️ Read This First

Before using deny rules, understand these fundamental limitations:

### 1. Tool Independence

Each tool has a **separate permission namespace**. A file-level deny does NOT block bash commands:

```json
{
  "deny": ["Read(.env)"]
}
```

**This ONLY blocks:**
- ✅ The Read tool: `Read(.env)`

**This does NOT block:**
- ❌ `Bash(cat .env)`
- ❌ `Bash(grep SECRET .env)`
- ❌ `Bash(head .env)`
- ❌ `Bash(python -c "open('.env').read()")`
- ❌ `Grep(SECRET, .env)` (Grep tool)
- ❌ `Glob(.env)` (Glob tool)

**To block comprehensively**, you'd need deny rules for **every tool** (Read, Bash, Grep, Glob, Edit, Write, WebFetch, etc.) with **every Bash command variant** (cat, less, more, head, tail, grep, awk, sed, python, node, etc.).

This quickly becomes **impractical** - which is why deny rules aren't suitable for security.

### 2. Pattern Matching Constraints

**Bash permissions:** Prefix matching only
- No regex
- No wildcards
- No pattern matching

**Bash pattern syntax:**
- `Bash(git status)` — Matches exactly "git status" (no arguments)
- `Bash(git status:*)` — Matches "git status" with any arguments: "git status .", "git status --short", etc.
- The `:*` suffix allows any arguments after the prefix

**File permissions:** Glob matching
- Better than Bash, but still limited
- Can't express complex conditions

```json
{
  "deny": [
    "Bash(cat .env:*)",              // Only blocks commands starting with "cat .env"
    "Bash(cd /tmp && cat .env:*)"    // Different prefix - NOT blocked
  ]
}
```

### 3. Bypass Techniques

Deny rules are easily bypassed:

**Indirect access:**
```bash
cp .env temp.txt && cat temp.txt     # Copy then read
```

**Tool substitution:**
```bash
head .env                             # Use different command
python -c "print(open('.env').read())"  # Use programming language
```

**Script execution:**
```json
{
  "deny": ["Bash(cat .env:*)"]
}
```
```bash
# Create script that reads .env
echo "cat .env" > script.sh
chmod +x script.sh
./script.sh                           # Bypass - different prefix
```

**Command chaining:**
```bash
cd /project && cat .env               # Different prefix than "cat .env"
```

**Note:** Recent Claude Code versions detect some shell operators (`&&`, `||`, `;`) in commands, but this detection has limitations and shouldn't be relied upon for security.

### 4. No Runtime Inspection

Permissions are checked **before execution**. Claude Code cannot:
- Inspect what a script actually does
- Analyze command behavior at runtime
- Detect what files a program will access

```json
{
  "deny": ["Read(.env)"]
}
```

```bash
# Script contains: cat .env
./my-script.sh                        # Deny rule can't see inside
```

### 5. Configuration Hierarchy Complexity

With 5 configuration levels, it can be difficult to:
- Know which rule is actually applying
- Debug why an operation was blocked
- Override rules from different sources

### 6. Scalability Issues

Comprehensive protection requires:
- Hundreds of deny rules
- Covering multiple tools
- Covering command variants
- Ongoing maintenance

This is **impractical and still bypassable**.

### 7. Sandbox Bypass

Some read-only commands execute in a sandboxed mode without triggering permission checks at all. Commands like `ls`, `cat`, `grep`, `find`, and `diff` may run without prompting, regardless of your deny configuration.

**Why this matters:**
- You might think your deny rules are working when commands actually ran in sandbox mode
- Another reason deny rules aren't reliable for security
- Sandbox behavior may vary across Claude Code versions

## What Deny Rules ARE Good For

Despite limitations, deny rules excel at specific workflow and resource management tasks:

### 1. Resource & Cost Management

**Save tokens and improve performance** by blocking large, irrelevant files:

```json
{
  "deny": [
    // Dependencies (often 100k+ files)
    "Read(node_modules/**)",
    "Read(vendor/**)",                // PHP/Go dependencies
    "Read(.pnp.cjs)",                 // Yarn PnP
    "Grep(node_modules/**)",          // Also block grepping dependencies
    "Glob(node_modules/**)",          // Also block globbing dependencies

    // Build artifacts
    "Read(build/**)",
    "Read(dist/**)",
    "Read(out/**)",
    "Read(target/**)",                // Rust build directory

    // Minified/compiled code
    "Read(*.min.js)",
    "Read(*.map)",

    // Lockfiles (large, low value)
    "Read(package-lock.json)",
    "Read(yarn.lock)",
    "Read(Cargo.lock)",
    "Read(Gemfile.lock)",

    // Git internals
    "Read(.git/objects/**)"
  ]
}
```

**Benefits:**
- Saves real money on token costs
- Faster context loading
- Focuses Claude on relevant source code
- Prevents wasted time reading generated files

### 2. Workflow Guardrails

**Prevent accidental mistakes** during development:

```json
{
  "deny": [
    // Prevent accidental pushes to protected branches
    "Bash(git push origin main:*)",
    "Bash(git push origin master:*)",

    // Prevent accidental publishing
    "Bash(npm publish:*)",
    "Bash(cargo publish:*)",

    // Prevent accidental deletion of version control
    "Bash(rm -rf .git:*)",
    "Bash(rm -rf .git/*:*)"
  ]
}
```

**Benefits:**
- Safety net for destructive operations
- Communication preferences with Claude
- Force confirmation before risky actions

### 3. Focus Management

**Guide Claude's attention** to relevant code:

```json
{
  "deny": [
    // Don't look at old code
    "Read(deprecated/**)",
    "Read(legacy/**)",
    "Read(archive/**)",

    // Stay out of experiments
    "Read(experiments/**)",
    "Read(playground/**)",

    // Ignore documentation in other languages
    "Read(docs/ja/**)",               // Japanese docs
    "Read(docs/zh/**)"                // Chinese docs
  ]
}
```

**Benefits:**
- Prevents context pollution
- Keeps Claude focused on active code
- Reduces confusion from outdated implementations

### 4. Noise Reduction

**Filter out low-signal files**:

```json
{
  "deny": [
    // Test fixtures (large, repetitive)
    "Read(test/fixtures/**)",
    "Read(test/mocks/**)",
    "Read(**/__snapshots__/**)",

    // Logs
    "Read(**/*.log)",
    "Read(logs/**)",

    // Databases
    "Read(**/*.sqlite)",
    "Read(**/*.db)",

    // Cache directories
    "Read(.cache/**)",
    "Read(.pytest_cache/**)",
    "Read(.mypy_cache/**)"
  ]
}
```

**Benefits:**
- Improves signal-to-noise ratio
- Focuses on actual source code
- Reduces token usage

## Common Misconceptions

### ❌ "Deny rules protect my secrets"

**NO.** Deny rules are:
- Tool-specific (file deny ≠ bash deny)
- Easily bypassed (copy, script execution, tool substitution)
- Based on static pattern matching
- Not designed for security

**For actual secret protection:**

1. **Use hooks** - PreToolUse hooks provide tool-agnostic protection and search entire command strings

2. **Environment isolation** - Use containers, VMs, or sandboxing

3. **Secret management** - Use Vault, AWS Secrets Manager, 1Password

4. **Never commit secrets** - Use `.gitignore` and environment variables

### ❌ "I can block all dangerous operations"

**NO.** Comprehensive coverage requires:
- Hundreds of deny rules
- Rules for every tool (Read, Bash, Grep, Glob, Edit, Write, WebFetch, WebSearch, NotebookEdit, Task, etc.)
- Rules for every Bash command variant (cat, head, tail, less, more, grep, awk, sed, python, node, ruby, perl, etc.)
- Ongoing maintenance as new tools/commands emerge

This is **impractical and still bypassable**.

**For actual security:**
- Use hooks and system-level controls
- Don't rely on permissions for protection

### ❌ "Specific deny rules override allow rules"

**Partially true.**

Within the same configuration source:
- ✅ Deny > Ask > Allow (deny always wins)

Across configuration sources:
- Configuration hierarchy matters (managed > workspace > user)
- A less-specific deny from a higher-priority source beats a more-specific allow from a lower-priority source

**Debugging tip:** Check all 5 configuration levels to understand which rule is applying.

### ❌ "Bash denies block all access"

**NO.** Bash denies only block commands with matching **prefixes**:

```json
{
  "deny": ["Bash(cat .env:*)"]
}
```

**Blocks:**
- ✅ `cat .env`

**Does NOT block:**
- ❌ `head .env` (different command)
- ❌ `cd /tmp && cat .env` (different prefix)
- ❌ `./read-env.sh` (script execution)
- ❌ `python -c "open('.env').read()"` (different tool)

**File-level denies** are more effective but still tool-specific:

```json
{
  "deny": ["Read(.env)"]
}
```

**Blocks:**
- ✅ Read tool only

**Does NOT block:**
- ❌ Bash tool (`cat .env`, `grep SECRET .env`, etc.)
- ❌ Grep tool (`Grep(SECRET, .env)`)
- ❌ Glob tool (`Glob(.env)`)
- ❌ Edit tool
- ❌ Write tool

## Pattern Examples

### Blocking Dependencies

```json
{
  "deny": [
    // JavaScript
    "Read(node_modules/**)",
    "Read(package-lock.json)",
    "Read(yarn.lock)",
    "Read(.pnp.cjs)",

    // PHP
    "Read(vendor/**)",
    "Read(composer.lock)",

    // Python
    "Read(venv/**)",
    "Read(.venv/**)",
    "Read(Pipfile.lock)",

    // Ruby
    "Read(vendor/bundle/**)",
    "Read(Gemfile.lock)",

    // Go
    "Read(vendor/**)",
    "Read(go.sum)",

    // Rust
    "Read(target/**)",
    "Read(Cargo.lock)",

    // .NET
    "Read(bin/**)",
    "Read(obj/**)",

    // Java
    "Read(.gradle/**)",
    "Read(build/**)"
  ]
}
```

### Blocking Build Artifacts

```json
{
  "deny": [
    "Read(build/**)",
    "Read(dist/**)",
    "Read(out/**)",
    "Read(.next/**)",                 // Next.js
    "Read(.nuxt/**)",                 // Nuxt
    "Read(.output/**)",               // Nitro
    "Read(*.min.js)",
    "Read(*.min.css)",
    "Read(*.map)",
    "Read(**/*.bundle.js)"
  ]
}
```

### Blocking Large Files

```json
{
  "deny": [
    // Logs
    "Read(**/*.log)",
    "Read(logs/**)",

    // Databases
    "Read(**/*.sqlite)",
    "Read(**/*.db)",
    "Read(**/*.sql)",

    // Binary files
    "Read(**/*.exe)",
    "Read(**/*.dll)",
    "Read(**/*.so)",
    "Read(**/*.dylib)",

    // Media files (if not relevant)
    "Read(**/*.mp4)",
    "Read(**/*.mov)",
    "Read(**/*.mp3)",
    "Read(**/*.wav)"
  ]
}
```

### Blocking Cache Directories

```json
{
  "deny": [
    "Read(.cache/**)",
    "Read(__pycache__/**)",
    "Read(.pytest_cache/**)",
    "Read(.mypy_cache/**)",
    "Read(.ruff_cache/**)",
    "Read(.tox/**)",
    "Read(.coverage)"
  ]
}
```

### Workflow Protection (NOT Security)

```json
{
  "deny": [
    // Git operations
    "Bash(git push origin main:*)",
    "Bash(git push origin master:*)",
    "Bash(git push --force:*)",
    "Bash(git push -f:*)",

    // Publishing
    "Bash(npm publish:*)",
    "Bash(yarn publish:*)",
    "Bash(cargo publish:*)",
    "Bash(gem push:*)",

    // Destructive operations
    "Bash(rm -rf:*)",
    "Bash(rm -fr:*)"
  ]
}
```

**Note:** These provide workflow guardrails but are NOT security protections (easily bypassed).

## For Security: Use Hooks Instead

### Why Deny Rules Don't Work for Security

1. **Tool-specific** - Need rules for every tool
2. **Easily bypassed** - Many workarounds
3. **Prefix matching** - Bash denies only match command prefixes
4. **No runtime inspection** - Can't see what scripts do
5. **Maintenance burden** - Requires hundreds of rules

### The Proper Security Solution: Hooks

Use PreToolUse hooks for protecting secrets and credentials. See Claude Code documentation on implementing hooks.

### Why Hooks Are Better for Security

**Tool-agnostic:**
- One hook blocks Read, Bash, Grep, Glob, Edit, Write, WebFetch, and all other tools
- No need for separate rules per tool (would need 17+ deny rules otherwise)

**Full string search:**
- Detects sensitive files anywhere in commands
- Not limited to prefix matching
- Catches bypasses like `cd /tmp && cat .env`

**Upfront context:**
- SessionStart hooks warn Claude about blocked files
- Claude knows not to attempt access

**Reliable protection:**
- Can block entire categories of files (e.g., all `.env*` variants)
- Pattern-based or exact-match protection
- Intercepts before tool execution

### Common Files to Protect with Hooks

**Shell configuration:**
- `.bashrc`, `.zshrc`, `.bash_profile`, `.zsh_profile`, `.profile`

**Environment files:**
- `.env`, `.env.local`, `.env.production`, `.env.development`, `.env.staging`, `.env.test`

**Cloud credentials:**
- `.aws/`, `.config/gcloud/`, `.azure/`, `.kube/`

**SSH and certificates:**
- `.ssh/`, `*.pem`, `*.key`, `*.pfx`, `*.p12`

**API keys and tokens:**
- `.npmrc`, `.pypirc`, `.gitconfig`, `.git-credentials`, `.docker/config.json`

### Using Hooks + Deny Rules Together

**Best practice:**
- Use **hooks** for security (secrets, credentials)
- Use **deny rules** for workflow (dependencies, build artifacts)

```json
{
  "permissions": {
    "deny": [
      // Workflow controls (NOT security)
      "Read(node_modules/**)",
      "Read(build/**)",
      "Bash(git push origin main:*)"
    ]
  }
}
```

Plus implement PreToolUse hooks for actual security.

## Debugging Deny Rules

### Why Is My Operation Blocked?

1. **Check configuration hierarchy:**
   - Managed settings (highest priority)
   - Workspace settings
   - Folder settings
   - Project settings
   - User global settings (lowest priority)

2. **Verify pattern syntax:**
   - Bash permissions: Prefix matching only
   - File permissions: Glob pattern matching
   - Check for typos in patterns

3. **Test with simpler patterns:**
   ```json
   {
     "deny": [
       "Read(src/**/*.test.js)"    // Specific - might not match
     ]
   }
   ```
   Try broader pattern:
   ```json
   {
     "deny": [
       "Read(src/**)"              // Broader - easier to debug
     ]
   }
   ```

4. **Use allow rules to override:**
   - Deny takes precedence within same config source
   - But allow from higher-priority source can override deny from lower-priority source

### Common Issues

**Pattern doesn't match:**
```json
{
  "deny": ["Read(./node_modules/**)"]  // Leading ./ might not match
}
```
Try without leading `./`:
```json
{
  "deny": ["Read(node_modules/**)"]
}
```

**Bash prefix doesn't match:**
```json
{
  "deny": ["Bash(cat .env:*)"]          // Only matches "cat .env"
}
```
Command starts differently:
```bash
cd /tmp && cat .env                     # NOT blocked (starts with "cd")
```

**Tool-specific deny:**
```json
{
  "deny": ["Read(.env)"]                // Only blocks Read tool
}
```
Bash commands not blocked:
```bash
cat .env                                # NOT blocked (Bash tool, not Read)
```

### Getting Help

If deny rules aren't working as expected:

1. Simplify your patterns
2. Check all 5 configuration levels
3. Verify you're using the right tool name (Read vs Bash vs Grep)
4. For security needs, use hooks instead of deny rules
