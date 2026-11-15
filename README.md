# ai-dev-os_Claude

AI DEV OS を組み込んだ Claude Code のユーザー設定（`~/.claude`）を、別の PC に再現するためのリポジトリです。

## 含まれるもの

| パス | 内容 | インストール先 |
| --- | --- | --- |
| `claude/CLAUDE.md` | グローバル指示（AI DEV OS ガイドラインの参照先） | `~/.claude/CLAUDE.md` |
| `claude/settings.template.json` | env（`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` など）、hooks、無効化プラグイン、statusLine | `~/.claude/settings.json` |
| `claude/skills/ai-dev-os-*` | `/ai-dev-os-plan` などのスキル | `~/.claude/skills/` |
| `claude/docs/guidelines/` | プロジェクト固有ガイドライン（`python-windows.md`） | `~/.claude/docs/guidelines/` |
| `claude/statusline.*` | ステータスライン | `~/.claude/` |
| `claude/.ai-dev-os.yaml` | ai-dev-os CLI の構成 | `~/.claude/` |
| `dependencies.txt` | 外部リポジトリ（ルール集・プラグイン・antivibe）とコミット | `~/.claude/docs/ai-dev-os` ほか |
| `extras/memory/` | AI DEV OS ガイドラインに従うよう指示するメモリ（プロジェクト単位） | `~/.claude/projects/<project>/memory/` |

## 含めていないもの

認証情報（`.credentials.json`、`.claude.json`、`settings.local.json`）、会話履歴・メモリ（`projects/`、`sessions/` など）、キャッシュ、バックアップ、Claude Code 本体のインストーラー（`install.cmd`）、`~/.claude` に置いていた個人ツール（`comfyui_studio` など）は含めていません。

マシン固有の絶対パスはプレースホルダーにしてあり、インストール時に置き換えます。

- `{{CLAUDE_HOME}}`（`settings.template.json` の statusLine）→ インストール先の `.claude` フォルダ
- `{{PROJECT_DIR}}`（`extras/memory`）→ `-ProjectDir` で指定したフォルダ

## 前提

- Claude Code
- Git（Windows では Git for Windows。hooks が `bash` を使います）
- Python 3（ステータスライン）
- jq（hooks。Windows は `winget install jqlang.jq`）

## インストール（Windows）

```powershell
git clone https://github.com/shio11/ai-dev-os_Claude.git
cd ai-dev-os_Claude
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

プロジェクト用のメモリも入れる場合:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ProjectDir C:\path\to\my-python-app
```

オプション:

- `-ClaudeHome <path>`: インストール先（既定 `%USERPROFILE%\.claude`）
- `-SkipSettings`: `settings.json` を上書きしない
- `-Latest`: 外部リポジトリを固定コミットではなく最新で取得する

## インストール（macOS / Linux / Git Bash）

```bash
./install.sh --project-dir ~/path/to/my-python-app
```

オプションは PowerShell 版と同じです（`--claude-home`、`--skip-settings`、`--latest`）。

## 上書きとバックアップ

上書きする既存ファイルは `~/.claude/backups/ai-dev-os-install-<日時>/` に退避します。メモリは既存ファイルがあれば上書きしません。インストール後は Claude Code を再起動してください。

## 設定を更新したとき

元の PC で `~/.claude` の設定を変えたら、該当ファイルをこのリポジトリの `claude/` にコピーしてコミットします。`settings.json` は statusLine の絶対パスを `{{CLAUDE_HOME}}` に戻してから `claude/settings.template.json` に保存してください。
