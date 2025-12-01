# skill-eval

Eval harness for Claude Code skills and plugins.

## Overview

This CLI tool runs test cases against LLM-powered skills and scores outputs using:

- **Deterministic checks**: File existence, pattern matching
- **LLM-as-judge**: Gemini API for semantic evaluation

## Setup

```bash
pnpm install
```

Set your Gemini API key:

```bash
export GEMINI_API_KEY=your-api-key-here
```

## Usage

Run eval for a plugin:

```bash
pnpm start <plugin-name>
```

Or directly with tsx:

```bash
tsx bin/run-eval.ts <plugin-name>
```

## Configuration

Create an `eval.yaml` in your working directory. See `example-eval.yaml` for reference.

### Config Structure

```yaml
plugin: plugin-name
description: Optional description
testCases:
  - name: Test case name
    input: Input prompt for the LLM skill
    setup: # Optional
      - type: create-file
        path: config.json
        content: |
          { "key": "value" }
    checks:
      - type: file-exists
        path: output.txt
      - type: contains-pattern
        path: output.txt
        pattern: regex-pattern
      - type: llm-judge
        prompt: Evaluation criteria
        weight: 2 # Optional, default 1
```

## Scorers

### file-exists

Checks if a file exists at the specified path.

### contains-pattern

Checks if a file contains a regex pattern.

### llm-judge

Uses Gemini to evaluate output semantically based on a prompt.

## Development

Format code:

```bash
pnpm format
```

Lint code:

```bash
pnpm lint
```

## TODO

- [ ] Implement actual Claude Code skill invocation
- [ ] Add command execution in setup steps
- [ ] Add more scorer types (exit code, performance, etc.)
- [ ] Add JSON output format for CI integration
- [ ] Add parallel test execution
