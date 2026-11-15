# AI Dev OS Rules — JavaScript

JavaScript version of [yunbow/ai-dev-os-rules-typescript](https://github.com/yunbow/ai-dev-os-rules-typescript) (MIT, see `LICENSE`), adapted for JavaScript that runs **without a build step**:

* **Browser UI** started from a Python app, without npm — `frameworks/browser`
* **Node.js tools** (CLI, MCP server) — `frameworks/nodejs-cli`

## How it differs from the TypeScript rules

* Types are written in JSDoc and checked by `checkJs` (`jsconfig.json`) instead of `.ts` files.
* Browser UI: schema libraries (Zod) are replaced by guard / factory functions; business rules stay in Python. Node.js tools may still use Zod.
* Next.js, Prisma, server, auth, and deployment rules are removed (they belong to the Python side or do not apply).
* `frameworks/browser` is new; `frameworks/nodejs-cli` is converted from TypeScript (no tsc / tsx; node:test instead of Vitest). `frameworks/nextjs` is not carried over.

## Contents (03_guidelines)

| File | Source |
|---|---|
| common/ai-coding.md, comment-format.md, *-prompt.md | Copied from the TypeScript rules with JS adjustments |
| common/code.md, naming.md, validation.md, error-handling.md, security.md, testing.md, performance.md | Rewritten for browser JS, keeping the TypeScript rules' structure and intent |
| frameworks/browser/project-structure.md | Project-specific rules for the Python-started browser UI |
| frameworks/nodejs-cli/*.md | Converted from the TypeScript rules (code examples in JSDoc form) |

Not carried over: cicd, cors, env, i18n, logging, rate-limiting, and all nextjs files. L1/L2 (philosophy, decision criteria) are shared with the Python rules in `~/.claude/docs/ai-dev-os`.

Base commit of the TypeScript rules: `312ab6f`.
