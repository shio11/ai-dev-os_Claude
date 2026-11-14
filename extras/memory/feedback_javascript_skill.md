---
name: feedback-javascript-skill
description: JavaScript（HTML内スクリプト含む）の新規作成・修正前に .agents/skills/javascript/SKILL.md を読んで従う
metadata:
  node_type: memory
  type: feedback
---

JavaScript の新規作成、または既存の JS・HTML 内スクリプトを修正する前に、必ず `{{PROJECT_DIR}}/.agents/skills/javascript/SKILL.md` を読み、そのルールに従う（Python が起動するアプリの画面としての JS、読み込み方式の判定、app/api/types/lib/views 構成、既存コードは変更箇所のみ適用）。

**Why:** ユーザーが JS 用スキルを作成し、自動で読み込まれない置き場所のためメモリでの適用を指示した（2026-10-31）。
**How to apply:** JS に着手する最初の操作で SKILL.md を Read する。medini analyze 等の組み込み JS エンジン用スクリプトは対象外。Python 側も触る場合は [[feedback-python-skill]] も併せて読む。
