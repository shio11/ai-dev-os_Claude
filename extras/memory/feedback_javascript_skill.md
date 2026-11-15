---
name: feedback-javascript-skill
description: JavaScript の実装は ~/.claude/CLAUDE.md が参照する AI DEV OS の JS ガイドラインに従う（TypeScript は不使用、旧 SKILL.md は廃止）
metadata:
  node_type: memory
  type: feedback
---

JavaScript の実装は、`~/.claude/CLAUDE.md` が参照する AI DEV OS ガイドライン（`~/.claude/docs/ai-dev-os-rules-javascript` の common と、ブラウザ画面は frameworks/browser、Node.js ツールは frameworks/nodejs-cli）に従う。TypeScript は使わない（JSDoc＋checkJs で型を付ける）。`.agents/skills/javascript/SKILL.md` は廃止済みで、読まない。

**Why:** ルールを AI DEV OS ガイドラインに一本化し、旧 SKILL.md は削除した（2026-11-15）。
**How to apply:** JS に着手する前に CLAUDE.md のガイドラインを読む。Python も触る場合は [[feedback-python-skill]] も参照。
