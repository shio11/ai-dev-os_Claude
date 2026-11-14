---
name: feedback-python-skill
description: Python新規着手時は必ず .agents/skills/python/SKILL.md を先に読んで従う
metadata:
  node_type: memory
  type: feedback
---

Pythonコードを新規に実装・生成する前に、必ず `{{PROJECT_DIR}}/.agents/skills/python/SKILL.md` を読み、そのルール（OOP・SRP・カプセル化・規模別構成・main.pyは組み立てのみ・構成案を先に提示）に従う。

**Why:** drbfm_auto 実装時に読まずに関数型で作り、ルール違反を指摘された（2026-10-12）。
**How to apply:** 新規Python着手の最初の操作でSKILL.mdをReadする。グローバルCLAUDE.mdの関数型志向と衝突する場合は、不変クラス＋副作用を境界に集める形で両立させる。
