# Ask Permissions Best Practices

Ask rules prompt the user for confirmation before allowing tool operations.

## Table of Contents

- [When to Use Ask Rules](#when-to-use-ask-rules)
- [Recommended Ask Patterns](#recommended-ask-patterns)
  - [Git Operations](#git-operations)
  - [Package and Dependency Management](#package-and-dependency-management)
  - [Critical Configuration Files](#critical-configuration-files)
  - [Database Operations](#database-operations)
  - [Network and External Operations](#network-and-external-operations)
- [Balancing Security and Convenience](#balancing-security-and-convenience)
- [Examples by Use Case](#examples-by-use-case)
  - [Code Review Workflow](#code-review-workflow)
  - [Feature Development](#feature-development)
  - [Production Deployment](#production-deployment)
- [Common Mistakes](#common-mistakes)
- [Decision Framework](#decision-framework)

## When to Use Ask Rules

Use ask rules for operations that:
- **Modify external state** - git push, deploying, publishing
- **Change dependencies** - npm install, pip install, cargo add
- **Modify critical files** - package.json, Cargo.toml, requirements.txt
- **Could have side effects** - Database migrations, API calls
- **Are infrequent but important** - Creating releases, updating versions

**Ask provides:**
- Review opportunity before execution
- Visibility into what Claude wants to do
- Chance to catch mistakes or unintended operations
- Security without completely blocking functionality

## Recommended Ask Patterns

### Git Operations

**Destructive or Publishing Operations:**

```json
{
  "permissions": {
    "ask": [
      "Bash(git push:*)",          // Publishing changes to remote
      "Bash(git commit:*)",        // Creating commits
      "Bash(git rebase:*)",        // History rewriting
      "Bash(git merge:*)",         // Merging branches
      "Bash(git reset:*)",         // Resetting state
      "Bash(git branch -d:*)",     // Deleting branches
      "Bash(git tag:*)",           // Creating/pushing tags
      "Bash(git stash:*)",         // Stashing changes
      "Bash(git cherry-pick:*)",   // Cherry-picking commits
      "Bash(git revert:*)"         // Reverting commits
    ]
  }
}
```

**Why ask:**
- `git push` publishes to remote (could break CI, affect team)
- `git commit` creates permanent history
- `git rebase`/`reset` can lose work if misused
- `git merge` could create conflicts
- `git branch -d` permanently deletes branches

**Allow instead (read-only):**
```json
{
  "allow": [
    "Bash(git status)",           // Read-only, safe
    "Bash(git diff:*)",           // Read-only, safe
    "Bash(git log:*)",            // Read-only, safe
    "Bash(git show:*)",           // Read-only, safe
    "Bash(git branch)"            // View branches (without -d)
  ]
}
```

### Package and Dependency Management

```json
{
  "permissions": {
    "ask": [
      // Node.js
      "Bash(npm install:*)",       // Modifies node_modules, package-lock
      "Bash(npm uninstall:*)",     // Removes dependencies
      "Bash(npm update:*)",        // Updates dependencies
      "Bash(yarn add:*)",
      "Bash(yarn remove:*)",
      "Bash(pnpm add:*)",
      "Bash(pnpm remove:*)",

      // Python
      "Bash(pip install:*)",       // Modifies Python environment
      "Bash(pip uninstall:*)",     // Removes Python packages
      "Bash(poetry add:*)",
      "Bash(poetry remove:*)",

      // Rust
      "Bash(cargo add:*)",         // Adds Rust dependencies
      "Bash(cargo remove:*)",      // Removes Rust dependencies

      // Ruby
      "Bash(bundle install:*)",    // Ruby gem installation
      "Bash(gem install:*)",

      // Go
      "Bash(go get:*)",            // Go package installation
      "Bash(go install:*)"
    ]
  }
}
```

**Why ask:**
- Dependencies affect build, runtime behavior, and security
- Lock files track exact versions (important for reproducibility)
- Installation can trigger post-install scripts (security risk)
- Updates can break compatibility
- Supply chain attacks via malicious packages

**Example review scenario:**
```
Claude: "I'd like to run: npm install lodash"
You can review:
- Is lodash needed? Is there a built-in alternative?
- Could this be a typosquatting attack? (lodash vs lod4sh)
- Will this affect bundle size?
```

### Critical Configuration Files

```json
{
  "permissions": {
    "ask": [
      // Package manifests
      "Edit(package.json)",        // Dependencies, scripts, metadata
      "Edit(Cargo.toml)",          // Rust project manifest
      "Edit(requirements.txt)",    // Python dependencies
      "Edit(Gemfile)",             // Ruby dependencies
      "Edit(pom.xml)",             // Maven dependencies
      "Edit(build.gradle)",        // Gradle configuration

      // Build/compiler configs
      "Edit(tsconfig.json)",       // TypeScript compiler options
      "Edit(webpack.config.js)",   // Build configuration
      "Edit(vite.config.ts)",      // Vite build config
      "Edit(rollup.config.js)",    // Rollup build config

      // CI/CD pipelines
      "Edit(.github/workflows/**)", // GitHub Actions
      "Edit(.gitlab-ci.yml)",      // GitLab CI
      "Edit(.circleci/config.yml)", // CircleCI
      "Edit(Jenkinsfile)",         // Jenkins

      // Docker
      "Edit(Dockerfile)",          // Container image definition
      "Edit(docker-compose.yml)"   // Container orchestration
    ]
  }
}
```

**Why ask:**
- These files control build, dependencies, and deployment
- Errors can break entire project
- Changes often have team-wide impact
- Review helps catch configuration mistakes

**Example scenarios:**
- Changing TypeScript `strict` mode could cause thousands of errors
- Modifying Dockerfile could create security vulnerabilities
- Editing CI pipeline could break deployments

### Database Operations

```json
{
  "permissions": {
    "ask": [
      // Database migrations
      "Bash(alembic:*)",           // SQLAlchemy migrations
      "Bash(knex migrate:*)",      // Knex migrations
      "Bash(sequelize-cli:*)",     // Sequelize migrations
      "Bash(prisma migrate:*)",    // Prisma migrations
      "Bash(rake db:*)",           // Rails database tasks
      "Bash(manage.py migrate:*)", // Django migrations
      "Bash(flyway:*)",            // Flyway migrations
      "Bash(liquibase:*)"          // Liquibase migrations
    ]
  }
}
```

**Why ask:**
- Migrations modify database schema (hard to reverse)
- Errors can cause data loss
- Production databases are especially sensitive
- Migrations should be reviewed for:
  - Data preservation
  - Performance impact (locking)
  - Rollback strategy

**Consider deny for production:**
```json
{
  "deny": [
    "Bash(prisma migrate:*)"      // Never auto-migrate in production
  ]
}
```

### Network and External Operations

```json
{
  "permissions": {
    "ask": [
      // HTTP requests
      "WebFetch",                  // HTTP requests to external services
      "Bash(curl:*)",              // Downloading/uploading via curl
      "Bash(wget:*)",              // Downloading files

      // Remote operations
      "Bash(scp:*)",               // Copying files over SSH
      "Bash(rsync:*)",             // Syncing files remotely
      "Bash(ssh:*)"                // Remote command execution
    ]
  }
}
```

**Why ask:**
- Network operations can leak data or credentials
- Downloading arbitrary files is security risk
- Remote commands on servers are high-stakes
- Review allows checking URLs and destinations

**Alternative - Deny for maximum security:**
```json
{
  "deny": ["WebFetch", "Bash(curl:*)", "Bash(wget:*)"]
}
```

Use deny when working with sensitive data that must not leave the system.

## Balancing Security and Convenience

### Too Restrictive (Annoying)

```json
{
  "ask": [
    "Bash(*)",                    // ❌ Asks for everything
    "Read(src/**)",               // ❌ Asks to read every source file
    "Edit(src/**)"                // ❌ Asks for every edit
  ]
}
```

**Problem:** User spends entire session clicking "Allow". This defeats the purpose:
- Causes "permission fatigue" - user stops reviewing
- Slows down workflow significantly
- Makes users frustrated with the tool

### Well-Balanced

```json
{
  "allow": [
    // Frequent, safe operations
    "Bash(npm run:*)",            // ✅ Safe, routine operations
    "Bash(git status)",
    "Bash(git diff:*)",
    "Read(src/**)",
    "Read(tests/**)",
    "Edit(src/**)",               // Allow editing source freely
    "Edit(tests/**)"
  ],
  "ask": [
    // Important, infrequent operations
    "Bash(git push:*)",           // ✅ Important, worth reviewing
    "Bash(git commit:*)",
    "Edit(package.json)",
    "Bash(npm install:*)"
  ],
  "deny": [
    // Critical security
    "Read(.env)",                 // ✅ Block entirely
    "Read(.env.*)",
    "Read(**/.env)",
    "Bash(rm:*)",
    "WebFetch"
  ]
}
```

**Principle:** Allow frequent safe operations, ask for important operations, deny dangerous operations.

### Finding the Right Balance

**Questions to ask:**
1. **How often will this operation occur?**
   - Frequent (multiple times per session) → Consider allow
   - Occasional (once per session) → Good for ask
   - Rare (once per project) → Definitely ask or deny

2. **What's the cost of a mistake?**
   - Low cost (easy to undo) → Consider allow
   - Medium cost (some work to undo) → Good for ask
   - High cost (data loss, security breach) → Deny

3. **Can I review it meaningfully?**
   - Yes, I understand what it does → Ask
   - No, too complex to review → Either allow (if safe) or deny (if risky)

## Examples by Use Case

### Code Review Workflow

**Goal:** Review pull requests, suggest improvements, run tests

```json
{
  "permissions": {
    "allow": [
      // Git inspection
      "Bash(git diff:*)",         // Review changes
      "Bash(git log:*)",          // View history
      "Bash(git show:*)",         // View specific commits
      "Bash(git branch)",

      // Code reading
      "Read(src/**)",             // Read code
      "Read(tests/**)",

      // Quality checks
      "Bash(npm run lint)",       // Check code quality
      "Bash(npm run test:*)",     // Run tests
      "Bash(npm run build)"       // Verify build works
    ],
    "ask": [
      // Suggestions
      "Edit(src/**)",             // Suggest code changes (review first)
      "Edit(tests/**)",           // Suggest test changes

      // Commits
      "Bash(git commit:*)"        // Commit suggestions (review message)
    ],
    "deny": [
      "Bash(git push:*)",         // Don't auto-push during review
      "Read(.env)",
      "Bash(rm:*)"
    ]
  }
}
```

**Workflow:**
1. Claude reads code freely
2. Claude runs tests/linting freely
3. Claude asks before making changes
4. You review suggested changes before they're applied

### Feature Development

**Goal:** Develop new features with Claude's help

```json
{
  "permissions": {
    "allow": [
      // Reading
      "Read(src/**)",
      "Read(tests/**)",
      "Read(docs/**)",

      // Editing (free editing during development)
      "Edit(src/**)",
      "Edit(tests/**)",
      "Edit(docs/**/*.md)",

      // Running
      "Bash(npm run:*)",
      "Bash(git diff:*)",
      "Bash(git status)"
    ],
    "ask": [
      // Important operations
      "Bash(git commit:*)",       // Review commit message
      "Bash(git push:*)",         // Review before publishing

      // Configuration changes
      "Edit(package.json)",       // Review dependency changes
      "Edit(tsconfig.json)",      // Review config changes

      // Dependencies
      "Bash(npm install:*)"       // Review new dependencies
    ],
    "deny": [
      "Read(.env)",
      "Read(**/.env)",
      "Bash(rm:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

**Workflow:**
1. Claude can edit source and tests freely (allows rapid iteration)
2. Claude asks before committing (you review changes)
3. Claude asks before installing packages (you review dependencies)

### Production Deployment

**Goal:** Maximum safety for production deployments

```json
{
  "permissions": {
    "allow": [
      // Inspection only
      "Bash(git status)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Read(src/**)",
      "Read(Dockerfile)",
      "Read(package.json)"
    ],
    "ask": [
      // Everything deployment-related requires approval
      "Bash(git tag:*)",          // Creating release tags
      "Bash(git push:*)",         // Pushing to remote

      // Build
      "Bash(npm run build)",      // Building for production
      "Bash(docker build:*)",     // Building container image

      // Publish
      "Bash(npm publish:*)",      // Publishing to registry
      "Bash(docker push:*)",      // Pushing to registry

      // Deploy
      "Bash(kubectl apply:*)",    // Applying Kubernetes config
      "Bash(helm upgrade:*)",     // Helm deployments
      "Bash(terraform apply:*)"   // Infrastructure changes
    ],
    "deny": [
      // Never auto-execute in production
      "Bash(kubectl delete:*)",   // Never auto-delete resources
      "Bash(rm:*)",
      "Read(.env)",
      "Read(**/.env)"
    ]
  }
}
```

**Principle:** For production, ask for everything deployment-related. Stakes are too high for auto-execution.

## Common Mistakes

### Asking for Read-Only Operations

```json
// ❌ Unnecessary friction
{
  "ask": ["Bash(git status)", "Bash(git diff:*)"]
}

// ✅ Allow safe read-only operations
{
  "allow": ["Bash(git status)", "Bash(git diff:*)"]
}
```

**Why bad:** Read-only operations are safe. Asking for confirmation adds unnecessary friction.

### Allowing Destructive Operations Instead of Asking

```json
// ❌ Risky: Auto-pushes without review
{
  "allow": ["Bash(git push:*)"]
}

// ✅ Ask for review first
{
  "ask": ["Bash(git push:*)"]
}
```

**Why important:** git push affects the entire team. You should review:
- Which branch is being pushed
- Are there commits you didn't intend?
- Is CI ready for these changes?

### Asking Instead of Denying for Dangerous Operations

```json
// ⚠️ Still risky: User might click "Allow" without thinking
{
  "ask": ["Bash(rm -rf:*)"]
}

// ✅ Block entirely
{
  "deny": ["Bash(rm:*)"]
}
```

**Why deny is better:** For truly dangerous operations, don't even offer the option. Users might:
- Click "Allow" out of habit
- Not fully understand the consequences
- Accidentally approve during rapid workflow

### Asking Too Frequently

```json
// ❌ Too many asks - permission fatigue
{
  "ask": [
    "Bash(npm run:*)",           // Asked multiple times per session
    "Edit(src/**)",              // Asked for every file edit
    "Read(tests/**)"             // Asked to read every test
  ]
}

// ✅ Reserve ask for important operations
{
  "allow": [
    "Bash(npm run:*)",
    "Edit(src/**)",
    "Read(tests/**)"
  ],
  "ask": [
    "Bash(git commit:*)",        // Once per commit
    "Bash(npm install:*)"        // Occasional
  ]
}
```

**Guideline:** If you'll see the prompt more than 5 times in a session, consider using allow instead.

## Decision Framework

When deciding between allow, ask, and deny:

```
┌─────────────────────────────────────────────────────────┐
│ Is the operation dangerous or could it lose data?       │
│ (rm, sudo, chmod, format, delete database)              │
└─────────────────────┬───────────────────────────────────┘
                      │
                  YES │ NO
                      │
                      ▼
              ┌───────────────┐
              │ Use DENY      │
              └───────────────┘

                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│ Does it modify external state?                          │
│ (git push, npm publish, deploy, database migration)     │
└─────────────────────┬───────────────────────────────────┘
                      │
                  YES │ NO
                      │
                      ▼
              ┌───────────────┐
              │ Use ASK       │
              └───────────────┘

                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│ Does it modify critical configuration?                  │
│ (package.json, CI/CD config, Dockerfile)                │
└─────────────────────┬───────────────────────────────────┘
                      │
                  YES │ NO
                      │
                      ▼
              ┌───────────────┐
              │ Use ASK       │
              └───────────────┘

                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│ Is it routine and safe?                                 │
│ (read source, run tests, git status)                    │
└─────────────────────┬───────────────────────────────────┘
                      │
                  YES │
                      │
                      ▼
              ┌───────────────┐
              │ Use ALLOW     │
              └───────────────┘
```

**Examples:**

| Operation | Dangerous? | External State? | Critical Config? | Routine? | → Rule |
|-----------|------------|-----------------|------------------|----------|--------|
| `git status` | No | No | No | Yes | **Allow** |
| `git push` | No | **Yes** | No | No | **Ask** |
| `rm -rf` | **Yes** | - | - | - | **Deny** |
| `Read(.env)` | **Yes** | - | - | - | **Deny** |
| `npm install` | No | **Yes** | No | No | **Ask** |
| `npm run test` | No | No | No | Yes | **Allow** |
| `Edit(package.json)` | No | No | **Yes** | No | **Ask** |
| `Read(src/**)` | No | No | No | Yes | **Allow** |

## Summary

**Use ask for:**
- git push, git commit (publishing changes)
- npm install, pip install (dependency changes)
- Editing package.json, Cargo.toml (critical configs)
- Database migrations (schema changes)
- WebFetch, curl (network operations with review)

**Balance ask with allow and deny:**
- **Allow**: Frequent, safe operations (tests, reading, builds)
- **Ask**: Important, occasional operations (commits, dependencies)
- **Deny**: Dangerous operations (rm, secrets, network exfiltration)

**Avoid permission fatigue:**
- Don't ask for routine operations
- Don't ask more than 5-10 times per session
- Reserve ask for meaningful review opportunities

**When in doubt:**
- Too risky? Use deny
- Important but safe? Use ask
- Routine and safe? Use allow
