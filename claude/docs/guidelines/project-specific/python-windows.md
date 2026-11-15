# Python 追加ルール（Windows・設計）

ai-dev-os の Python ガイドラインに無い、または補うルール。食い違う場合は ai-dev-os の frameworks/common を優先する。

## ファイルとパス
- ファイルの読み書きは必ず `encoding` を指定する。既定は `utf-8`、Excel で開く CSV は `utf-8-sig`、.bat は `cp932`。Windows の既定は cp932 のため、省略すると文字化けやエラーになる。
- パスは `pathlib.Path` で扱い、文字列の連結で作らない。

## エラー
- 利用者に見せるエラーメッセージには、どのファイルの何が原因かを含める。

## クラス設計
- 継承よりコンポジションを優先する。継承は is-a 関係が明確な場合だけ使う。
- 不変にできる属性は `@dataclass(frozen=True)` にする。
- インスタンス変数はカプセル化し、外部から直接書き換えさせない。対象は不正な状態を防ぐ必要がある属性に絞り、値を持つだけのクラスは `dataclass` で済ませて getter/setter を個別に書かない。

## 起動とエントリーポイント
- 利用者が起動するファイルは、アプリのフォルダ直下（pyproject.toml・`src/` と同じ階層。例: `Functional_safety_assistant_tool/main.py`）の `main.py` とし、そのフォルダで `uv run main.py` で起動する。上位のフォルダ（my-python-app など）には置かない。ソースは frameworks/python-cli/project-structure.md のとおり `src/{package}/` に置く。
- `main.py` には処理を書かない。`src` を import の検索先に加え、パッケージの `main()` を呼ぶだけにする（パッケージをインストールせずに起動できるようにするため）。
- `main.py` は uv に依存させず、uv を使わない場合も `python main.py` で起動できるようにする（`main.py` 自身の場所を基準に `src` を検索先に加える）。
  ```python
  import sys
  from pathlib import Path

  sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

  from {package}.__main__ import main  # noqa: E402

  if __name__ == "__main__":
      main()
  ```
- 起動処理は `src/{package}/__main__.py` の `main()` に置く（`python -m {package}` でも起動できる）。pyproject.toml の `[project.scripts]`（GUI は `[project.gui-scripts]`）にも同じ `main()` を登録する。
- 上位のフォルダに uv のプロジェクト（共有の `.venv`）がある場合は、アプリの pyproject.toml に `[tool.uv] managed = false` を書く。uv がアプリ用の `.venv`・`uv.lock` を作らず、上位の `.venv` で動くようにするため。
