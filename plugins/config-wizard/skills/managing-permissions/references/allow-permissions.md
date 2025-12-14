# Allow Permissions

Allow rules grant automatic permission for tool operations without user confirmation. Use them for safe, routine operations that you trust.

## Table of Contents

- [Core Principles](#core-principles)
- [Decision Framework](#decision-framework)
- [Common Safe Patterns](#common-safe-patterns)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
- [Validation Checklist](#validation-checklist)
- [Summary](#summary)

## Core Principles

### 1. Non-Destructive Operations

Allow operations that are safe and reversible. **Editing source code is safe** when you have version control.

**Safe operations:**
- Reading files
- Viewing status/diffs
- Editing source code (with git as safety net)
- Running tests that don't modify source
- Building to designated output directories

**Risky operations (use ask or deny instead):**
- Deleting files or directories
- Publishing packages or deploying
- Installing dependencies
- Modifying critical system files

**Example:**
```json
{
  "allow": [
    "Read(src/**)",              // ✅ Reading source
    "Edit(src/**)",              // ✅ Editing source (git protects you)
    "Bash(git status)",          // ✅ Read-only
    "Bash(npm run test)"         // ✅ Non-destructive
  ],
  "ask": [
    "Bash(git push:*)",          // ⚠️ Publishes changes
    "Bash(npm install:*)"        // ⚠️ Modifies dependencies
  ],
  "deny": [
    "Read(node_modules/**)",     // ❌ Wastes tokens
    "Bash(rm:*)"                 // ❌ Destructive
  ]
}
```

### 2. Specific, Not Generic

Allow specific commands you've reviewed and trust. Avoid wildcards that could execute unknown operations.

**Why this matters:** Wildcards mean you're trusting all current *and future* operations matching that pattern. As projects evolve, new commands/scripts get added that you haven't reviewed.

**Example:**
```json
// ✅ GOOD: Specific commands
{
  "allow": [
    "Bash(npm run test)",
    "Bash(npm run lint)",
    "Bash(npm run build)"
  ]
}

// ❌ BAD: Broad wildcard
{
  "allow": [
    "Bash(npm run:*)"  // Trusts ALL scripts in package.json
  ]
}
```

**When wildcards are acceptable:**
- Trailing wildcards for arguments: `Bash(git diff:*)`, `Bash(git log:*)`
- File patterns for reading: `Read(src/**/*.ts)`
- When the tool itself is safe: `Bash(git status:*)` (though `:*` is unnecessary here)

### 3. Scoped to Project Files

Allow access to source code and documentation. **Deny access to outputs and sensitive files.**

**Example:**
```json
// ✅ GOOD: Source and docs
{
  "allow": [
    "Read(src/**)",
    "Edit(src/**)",
    "Read(tests/**)",
    "Edit(tests/**)",
    "Read(docs/**)"
  ],
  "deny": [
    // Outputs (waste tokens)
    "Read(dist/**)",
    "Read(build/**)",
    "Read(node_modules/**)",

    // Sensitive files
    "Read(.env)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)"
  ]
}
```

**Why deny outputs:**
- Generated/compiled code wastes tokens
- Provides no useful context for the agent
- Gets regenerated anyway

**Why deny sensitive files:**
- Credentials and secrets should never be accessed
- Use hooks for comprehensive protection

### 4. Reviewed and Trusted

Only allow operations you've reviewed and understand. Consider what could happen if the operation runs 100 times without your knowledge.

**Questions to ask:**
- Do I know exactly what this command does?
- Have I reviewed the scripts/code it will execute?
- Would I be comfortable if this ran automatically in CI/CD?
- What's the worst case if this is abused or misconfigured?

### 5. Defense in Depth

Layer multiple protections:
- Allow rules for routine, safe operations
- Ask rules for operations requiring review
- Deny rules for outputs (save tokens) and sensitive files (security)

**Example:**
```json
{
  "allow": [
    "Read(src/**)",
    "Edit(src/**)",
    "Bash(npm run test)",
    "Bash(git status)"
  ],
  "ask": [
    "Bash(git commit:*)",
    "Bash(npm install:*)"
  ],
  "deny": [
    // Save tokens
    "Read(node_modules/**)",
    "Read(dist/**)",
    "Read(build/**)",

    // Security
    "Read(.env)",
    "Read(**/.env)",
    "Bash(rm:*)"
  ]
}
```

## Decision Framework

Use this framework to decide if an operation is safe to allow:

### Step 1: Is it non-destructive?
- ✅ Read-only operations → Consider allow
- ✅ Writes to designated output (dist/, build/) → Consider allow
- ❌ Modifies source, deletes files, publishes → Use ask or deny

### Step 2: Is it specific?
- ✅ Specific command or file path → Consider allow
- ⚠️ Wildcard that could match unknown items → Use ask
- ❌ Overly broad wildcard (`Bash(*)`, `Read(**)`) → Use ask or deny

### Step 3: Is it scoped to project files?
- ✅ Limited to project directories → Consider allow
- ❌ Could access system files, home directory, credentials → Add deny rules

### Step 4: Have I reviewed it?
- ✅ I know exactly what this does → Consider allow
- ❌ Uncertain about behavior → Use ask

### Step 5: Would I want to review this operation?
- ✅ Routine operation I do 10+ times per session → Allow
- ⚠️ Important but occasional operation → Use ask
- ❌ Critical or risky operation → Use ask or deny

**If uncertain at any step, use `ask` instead of `allow`.**

## Common Safe Patterns

### Read Operations

**Source code and documentation:**
```json
{
  "allow": [
    "Read(src/**)",
    "Read(lib/**)",
    "Read(app/**)",
    "Read(tests/**)",
    "Read(docs/**)",
    "Read(README.md)"
  ]
}
```

**Configuration files (non-sensitive):**
```json
{
  "allow": [
    "Read(package.json)",
    "Read(tsconfig.json)",
    "Read(.eslintrc.json)",
    "Read(.prettierrc)",
    "Read(Cargo.toml)",
    "Read(go.mod)",
    "Read(.gitignore)"
  ]
}
```

**Never allow reading:**
```json
// ❌ Contains secrets
"Read(.env)"
"Read(.env.*)"
"Read(**/.env)"
"Read(~/.aws/**)"
"Read(~/.ssh/**)"
"Read(config/credentials.json)"
```

### Read-Only Commands

**Version control:**
```json
{
  "allow": [
    "Bash(git status)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
    "Bash(git show:*)",
    "Bash(git branch)"        // Without -d flag
  ]
}
```

**File system:**
```json
{
  "allow": [
    "Bash(ls:*)",
    "Bash(pwd)",
    "Bash(find . -name:*)",
    "Bash(tree:*)"
  ]
}
```

### Development Commands

**Tests and checks:**
```json
{
  "allow": [
    "Bash(npm run test)",
    "Bash(npm run lint)",
    "Bash(cargo test)",
    "Bash(cargo check)",
    "Bash(pytest:*)",
    "Bash(go test:*)"
  ]
}
```

**Builds (to designated output):**
```json
{
  "allow": [
    "Bash(npm run build)",
    "Bash(cargo build)",
    "Bash(go build:*)",
    "Bash(make build)"
  ]
}
```

**Note:** Only allow build commands if you've reviewed that they:
- Write to designated output directories (dist/, build/, target/)
- Don't execute arbitrary scripts from config files
- Don't modify source code

### Source File Modifications

**Allow editing source files** - that's the agent's primary purpose:

```json
{
  "allow": [
    "Read(src/**)",
    "Edit(src/**)",
    "Write(src/**)",
    "Read(tests/**)",
    "Edit(tests/**)",
    "Write(tests/**)"
  ]
}
```

**Why this is safe:** Version control (git) is your safety net. You can review and revert changes.

**If you want more control:**
```json
{
  "allow": ["Read(src/**)"],
  "ask": [
    "Edit(src/**)",      // Review each change before applying
    "Write(src/**)"
  ]
}
```

### Output Directories

**Deny reading outputs** - they waste tokens and provide no useful context:

```json
{
  "deny": [
    "Read(dist/**)",
    "Read(build/**)",
    "Read(out/**)",
    "Read(target/**)",
    "Read(node_modules/**)",
    "Read(.next/**)",
    "Read(.nuxt/**)",
    "Read(.cache/**)"
  ]
}
```

**Why deny reading:**
- Minified/compiled code is unreadable
- Huge files waste tokens
- Generated code provides no useful context
- Gets regenerated on every build

**Writing to outputs:** Usually unnecessary since build tools handle this. Only allow if the agent needs to generate output files directly:

```json
{
  "allow": [
    "Write(coverage/**)",     // Coverage reports
    "Write(logs/*.log)"       // Log files
  ]
}
```

## Anti-Patterns to Avoid

### 1. Overly Broad Wildcards

```json
// ❌ BAD: Allows ANY command/file
{
  "allow": [
    "Bash(*)",
    "Read(**)",
    "Write(**)"
  ]
}

// ✅ GOOD: Specific patterns
{
  "allow": [
    "Bash(npm run test)",
    "Bash(git status)",
    "Read(src/**)",
    "Write(dist/**)"
  ]
}
```

### 2. Missing Sensitive File Protections

```json
// ❌ BAD: No protection for secrets
{
  "allow": ["Read(**)"]
}

// ✅ GOOD: Explicit denies for sensitive files
{
  "allow": ["Read(src/**)", "Read(tests/**)")],
  "deny": [
    "Read(.env)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)"
  ]
}
```

### 3. Allowing Destructive Operations

```json
// ❌ BAD: Can delete files
{
  "allow": ["Bash(rm:*)"]
}

// ✅ GOOD: Block or require review
{
  "deny": ["Bash(rm:*)"]
}
// or
{
  "ask": ["Bash(rm:*)"]
}
```

### 4. Allowing Package Installation Without Review

```json
// ❌ BAD: Installs arbitrary packages
{
  "allow": ["Bash(npm install:*)"]
}

// ✅ GOOD: Require review
{
  "ask": ["Bash(npm install:*)"]
}
```

**Why risky:**
- Post-install scripts can execute arbitrary code
- Typosquatting attacks (malicious packages with similar names)
- Supply chain attacks
- Modifies lock files affecting entire team

### 5. Allowing Broad File Writes

```json
// ❌ BAD: Can overwrite any file
{
  "allow": ["Write(**)"]
}

// ✅ GOOD: Limited to output directories
{
  "allow": [
    "Write(dist/**)",
    "Write(build/**)"
  ]
}
```

### 6. Not Layering Protections

```json
// ❌ BAD: Allow without protective denies
{
  "allow": [
    "Read(src/**)",
    "Bash(cat:*)"
  ]
}

// ✅ GOOD: Defense in depth
{
  "allow": [
    "Read(src/**)",
    "Bash(cat:*)"
  ],
  "deny": [
    "Read(.env)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)"
  ]
}
```

## Validation Checklist

Before adding an allow rule, verify:

### ✓ Non-Destructive
- [ ] Operation doesn't modify source code
- [ ] Doesn't delete files or directories
- [ ] Doesn't publish or deploy
- [ ] Writes only to designated output directories

### ✓ Specific
- [ ] Command/path is specific, not a broad wildcard
- [ ] If using wildcards, they're for arguments/subpaths only
- [ ] Pattern has clear, limited scope

### ✓ Scoped
- [ ] Limited to project directories
- [ ] Doesn't access system files
- [ ] Doesn't access user home directory
- [ ] Protected by deny rules for sensitive files

### ✓ Reviewed
- [ ] I know exactly what this operation does
- [ ] I've reviewed any scripts/code it executes
- [ ] I'm comfortable with this running automatically

### ✓ Appropriate
- [ ] This is a routine operation (used frequently)
- [ ] I wouldn't want to review this every time
- [ ] The operation is low-risk if misused

### ✓ Protected
- [ ] Sensitive files have explicit deny rules
- [ ] Dangerous operations are blocked or require review
- [ ] Multiple layers of protection are in place

**If any check fails, use `ask` or `deny` instead of `allow`.**

## Summary

**Core approach:**
1. **Allow source edits** - Reading and editing src/, tests/, docs/ is the agent's job
2. **Deny output reads** - Block node_modules/, dist/, build/ to save tokens
3. **Be specific** - Avoid broad wildcards, allow only what you've reviewed
4. **Layer protections** - Combine allow (routine), ask (review), deny (outputs + secrets)
5. **Use git as safety net** - Version control protects you from unwanted changes

**Key principle:** Allow routine operations. Deny token-wasting reads to generated files. Use `ask` for important operations requiring review.

**Priorities:**
- ✅ **Source code**: Allow reading/editing freely (that's what the agent does)
- ❌ **Outputs**: Deny reading (wastes tokens, no useful context)
- ❌ **Secrets**: Deny access (use hooks for comprehensive protection)
- ⚠️ **Important ops**: Use `ask` for git push, npm install, etc.
