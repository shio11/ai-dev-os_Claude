# Overview

> **Note:** The technology stack below is a sample configuration. Replace libraries based on your project's requirements. Files marked with `[Replaceable]` in this directory contain library-specific patterns — update the corresponding files when switching libraries.

## Purpose

This is a guideline for designing robust, maintainable CLI tools with Node.js and JavaScript (no build step), balancing usability, extensibility, testability, and developer productivity.

## Technology Stack

- Node.js (ES Module)
  - CLI Argument Parsing
  - Subcommand Routing
  - Process Lifecycle Management
  - File I/O & Streaming
- CLI Framework: Commander
- Validation: Zod
- Testing: node:test (built-in)
- Types: JSDoc + `jsconfig.json` (`checkJs`, `strict`) — no build step
- Dev Runner: `node --watch`
- Node.js: 22 LTS or later (`"engines": { "node": ">=22" }`)

### Replaceable Libraries

| Category | Current | Alternatives | Related Files |
|----------|---------|-------------|---------------|
| CLI Framework | Commander | yargs, clipanion, citty | `cli-design.md` |
| Validation | Zod | Valibot, ArkType | `config.md` |
| Testing | node:test | Vitest, Jest | — |
| Configuration | Custom resolver | cosmiconfig, c12 | `config.md` |
| Logging | Custom module logger | pino, winston, consola | — |

## Basic Principles

- Single-responsibility subcommands with clear input/output contracts
- Fail fast with meaningful error messages and exit codes
- Support both interactive and non-interactive (CI) environments
- Pipeline-based architecture for multi-step processing
- Deterministic output via caching and resumable execution
