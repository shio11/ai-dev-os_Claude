#!/usr/bin/env bash
# AI DEV OS 用 Claude Code 設定を ~/.claude にインストールする（macOS / Linux / Git Bash）。
#
# 使い方:
#   ./install.sh [--claude-home DIR] [--project-dir DIR] [--skip-settings] [--latest]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_ROOT/claude"
CLAUDE_HOME="${HOME}/.claude"
PROJECT_DIR=""
SKIP_SETTINGS=0
LATEST=0

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-home) CLAUDE_HOME="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --skip-settings) SKIP_SETTINGS=1; shift ;;
    --latest) LATEST=1; shift ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "不明な引数: $1" >&2; exit 1 ;;
  esac
done

BACKUP_DIR="$CLAUDE_HOME/backups/ai-dev-os-install-$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    local rel="${target#"$CLAUDE_HOME"/}"
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    cp -R "$target" "$BACKUP_DIR/$rel"
  fi
}

copy_with_backup() {
  backup_if_exists "$2"
  mkdir -p "$(dirname "$2")"
  cp -R "$1" "$2"
}

command -v git >/dev/null || { echo "git が見つかりません" >&2; exit 1; }
command -v jq >/dev/null || echo "警告: jq が見つかりません。hooks が動作しません。" >&2

mkdir -p "$CLAUDE_HOME"
echo "インストール先: $CLAUDE_HOME"

for f in CLAUDE.md .ai-dev-os.yaml statusline.py statusline.sh statusline-height-mode.txt; do
  copy_with_backup "$SRC/$f" "$CLAUDE_HOME/$f"
done

(cd "$SRC/docs" && find . -type f) | while read -r rel; do
  rel="${rel#./}"
  copy_with_backup "$SRC/docs/$rel" "$CLAUDE_HOME/docs/$rel"
done

for dir in "$SRC"/skills/*/; do
  name="$(basename "$dir")"
  dest="$CLAUDE_HOME/skills/$name"
  backup_if_exists "$dest"
  rm -rf "$dest"
  mkdir -p "$CLAUDE_HOME/skills"
  cp -R "$dir" "$dest"
done

if [ "$SKIP_SETTINGS" -eq 0 ]; then
  backup_if_exists "$CLAUDE_HOME/settings.json"
  home_escaped="$(printf '%s' "$CLAUDE_HOME" | sed 's/[&|]/\\&/g')"
  sed "s|{{CLAUDE_HOME}}|$home_escaped|g" "$SRC/settings.template.json" > "$CLAUDE_HOME/settings.json"
  echo "settings.json を書き込みました"
else
  echo "settings.json はスキップしました（--skip-settings）"
fi

grep -v '^#' "$REPO_ROOT/dependencies.txt" | grep -v '^[[:space:]]*$' | tr -d '\r' | while IFS='|' read -r path url ref; do
  dest="$CLAUDE_HOME/$path"
  if [ ! -d "$dest/.git" ]; then
    if [ -e "$dest" ]; then backup_if_exists "$dest"; rm -rf "$dest"; fi
    echo "clone: $url -> $path"
    git clone --quiet "$url" "$dest"
  else
    echo "更新: $path"
    git -C "$dest" fetch --quiet origin
  fi
  if [ -n "$ref" ] && [ "$LATEST" -eq 0 ]; then
    git -C "$dest" checkout --quiet "$ref"
  else
    git -C "$dest" pull --quiet --ff-only
  fi
done

if [ -n "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
  # Claude Code はプロジェクトパスの英数字以外を '-' にしてメモリフォルダ名にする
  encoded="$(printf '%s' "$PROJECT_DIR" | sed 's/[^A-Za-z0-9]/-/g')"
  mem_dir="$CLAUDE_HOME/projects/$encoded/memory"
  mkdir -p "$mem_dir"
  proj_escaped="$(printf '%s' "$PROJECT_DIR" | sed 's/[&|]/\\&/g')"
  for f in "$REPO_ROOT"/extras/memory/*; do
    dest="$mem_dir/$(basename "$f")"
    if [ -e "$dest" ]; then echo "既存のため残しました: $dest"; continue; fi
    sed "s|{{PROJECT_DIR}}|$proj_escaped|g" "$f" > "$dest"
  done
  echo "メモリ: $mem_dir"
fi

[ -d "$BACKUP_DIR" ] && echo "既存ファイルのバックアップ: $BACKUP_DIR"
echo "完了しました。Claude Code を再起動してください。"
