<#
.SYNOPSIS
  AI DEV OS 用 Claude Code 設定を ~/.claude にインストールする。

.PARAMETER ClaudeHome
  インストール先（既定: $env:USERPROFILE\.claude）

.PARAMETER ProjectDir
  指定すると、extras のメモリ（AI DEV OS ガイドラインに従う指示）を
  そのプロジェクトに設定する。

.PARAMETER SkipSettings
  settings.json を上書きしない。

.PARAMETER Latest
  外部リポジトリを固定コミットではなく最新で取得する。

.EXAMPLE
  .\install.ps1
  .\install.ps1 -ProjectDir C:\Users\me\Python\my-python-app
#>
[CmdletBinding()]
param(
    [string]$ClaudeHome = (Join-Path $env:USERPROFILE '.claude'),
    [string]$ProjectDir,
    [switch]$SkipSettings,
    [switch]$Latest
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$Src = Join-Path $RepoRoot 'claude'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $ClaudeHome "backups\ai-dev-os-install-$Stamp"

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

function Backup-IfExists([string]$Target) {
    if (Test-Path $Target) {
        $rel = $Target.Substring($ClaudeHome.TrimEnd('\', '/').Length).TrimStart('\', '/')
        $dest = Join-Path $BackupDir $rel
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item -Recurse -Force $Target $dest
    }
}

function Copy-WithBackup([string]$From, [string]$To) {
    Backup-IfExists $To
    New-Item -ItemType Directory -Force (Split-Path $To) | Out-Null
    Copy-Item -Recurse -Force $From $To
}

# --- 前提チェック ---
foreach ($cmd in 'git', 'python') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "$cmd が見つかりません。インストールしてから再実行してください。" }
}
foreach ($cmd in 'bash', 'jq') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Warning "$cmd が見つかりません。hooks が動作しません（Git for Windows と jq を入れてください: winget install jqlang.jq）。"
    }
}

New-Item -ItemType Directory -Force $ClaudeHome | Out-Null
Write-Host "インストール先: $ClaudeHome"

# --- ファイルのコピー ---
$files = 'CLAUDE.md', '.ai-dev-os.yaml', 'statusline.py', 'statusline.sh', 'statusline-height-mode.txt'
foreach ($f in $files) { Copy-WithBackup (Join-Path $Src $f) (Join-Path $ClaudeHome $f) }

$docsSrc = Join-Path $Src 'docs'
Get-ChildItem $docsSrc -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($docsSrc.Length).TrimStart('\', '/')
    Copy-WithBackup $_.FullName (Join-Path $ClaudeHome "docs\$rel")
}
Get-ChildItem (Join-Path $Src 'skills') -Directory | ForEach-Object {
    $dest = Join-Path $ClaudeHome "skills\$($_.Name)"
    Backup-IfExists $dest
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    Copy-Item -Recurse $_.FullName $dest
}

# --- settings.json（テンプレートのパスを置換） ---
if (-not $SkipSettings) {
    $target = Join-Path $ClaudeHome 'settings.json'
    Backup-IfExists $target
    $homeFwd = $ClaudeHome -replace '\\', '/'
    $json = (Get-Content -Raw -Encoding UTF8 (Join-Path $Src 'settings.template.json')).Replace('{{CLAUDE_HOME}}', $homeFwd)
    Write-Utf8NoBom $target $json
    Write-Host "settings.json を書き込みました"
} else {
    Write-Host "settings.json はスキップしました（-SkipSettings）"
}

# --- 外部リポジトリ ---
Get-Content -Encoding UTF8 (Join-Path $RepoRoot 'dependencies.txt') |
    Where-Object { $_ -and -not $_.StartsWith('#') } |
    ForEach-Object {
        $path, $url, $ref = $_.Split('|')
        $dest = Join-Path $ClaudeHome $path
        if (-not (Test-Path (Join-Path $dest '.git'))) {
            if (Test-Path $dest) { Backup-IfExists $dest; Remove-Item -Recurse -Force $dest }
            Write-Host "clone: $url -> $path"
            git clone --quiet $url $dest
            if ($LASTEXITCODE -ne 0) { throw "clone に失敗しました: $url" }
        } else {
            Write-Host "更新: $path"
            git -C $dest fetch --quiet origin
        }
        if ($ref -and -not $Latest) {
            git -C $dest checkout --quiet $ref
        } else {
            git -C $dest pull --quiet --ff-only
        }
    }

# --- プロジェクト用（任意） ---
if ($ProjectDir) {
    $ProjectDir = (Resolve-Path $ProjectDir).Path
    # Claude Code はプロジェクトパスの英数字以外を '-' にしてメモリフォルダ名にする
    $encoded = $ProjectDir -replace '[^A-Za-z0-9]', '-'
    $memDir = Join-Path $ClaudeHome "projects\$encoded\memory"
    New-Item -ItemType Directory -Force $memDir | Out-Null
    Get-ChildItem (Join-Path $RepoRoot 'extras\memory') -File | ForEach-Object {
        $dest = Join-Path $memDir $_.Name
        if (Test-Path $dest) { Write-Host "既存のため残しました: $dest"; return }
        $text = (Get-Content -Raw -Encoding UTF8 $_.FullName).Replace('{{PROJECT_DIR}}', $ProjectDir)
        Write-Utf8NoBom $dest $text
    }
    Write-Host "メモリ: $memDir"
}

if (Test-Path $BackupDir) { Write-Host "既存ファイルのバックアップ: $BackupDir" }
Write-Host "完了しました。Claude Code を再起動してください。"
