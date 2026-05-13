# setup-new-pc.ps1
# Windows 新規PC セットアップスクリプト
# 使い方: PowerShell を管理者で開いて実行
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\scripts\setup-new-pc.ps1

param(
    [string]$GDrivePath = "G:\",
    [switch]$SkipWinget,
    [switch]$SkipNpm,
    [switch]$SkipPip,
    [switch]$SkipClaude,
    [switch]$CaptureOnly
)

$ErrorActionPreference = "Stop"

function Log   { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Ok    { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# ----------------------------
# Winget パッケージ
# ----------------------------
$WingetPackages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Notepad++.Notepad++",
    "7zip.7zip",
    "Google.Chrome",
    "Anthropic.Claude",
    "rclone.rclone",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "GoLang.Go",
    "Rustlang.Rustup",
    "Microsoft.WindowsTerminal",
    "Microsoft.PowerShell"
)

function Install-WingetPackages {
    Log "=== Winget パッケージのインストール ==="
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Warn "winget が見つかりません。Microsoft Store から App Installer をインストールしてください。"
        return
    }
    foreach ($pkg in $WingetPackages) {
        Log "  $pkg"
        winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -ne 0) { Warn "  スキップ (インストール済みまたは失敗): $pkg" }
    }
    Ok "Winget パッケージ完了"
}

# ----------------------------
# npm グローバルパッケージ
# ----------------------------
function Restore-NpmPackages {
    $listFile = Join-Path $GDrivePath "packages\npm-globals.txt"
    if (-not (Test-Path $listFile)) { Warn "npm-globals.txt なし。スキップ"; return }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Warn "npm なし。スキップ"; return }

    Log "=== npm グローバルパッケージのインストール ==="
    Get-Content $listFile | Where-Object { $_ -ne "" } | ForEach-Object {
        Log "  $_"
        npm install -g $_ 2>$null
        if ($LASTEXITCODE -ne 0) { Warn "  失敗: $_" }
    }
    Ok "npm 完了"
}

# ----------------------------
# pip パッケージ
# ----------------------------
function Restore-PipPackages {
    $listFile = Join-Path $GDrivePath "packages\pip-requirements.txt"
    if (-not (Test-Path $listFile)) { Warn "pip-requirements.txt なし。スキップ"; return }
    if (-not (Get-Command pip -ErrorAction SilentlyContinue)) { Warn "pip なし。スキップ"; return }

    Log "=== pip パッケージのインストール ==="
    pip install --user -r $listFile
    if ($LASTEXITCODE -ne 0) { Warn "一部パッケージのインストールに失敗しました" }
    Ok "pip 完了"
}

# ----------------------------
# Claude Code スキル・設定の復元
# ----------------------------
function Restore-ClaudeSettings {
    $claudeSrc = Join-Path $GDrivePath ".claude"
    if (-not (Test-Path $claudeSrc)) { Warn "Google Drive に .claude なし。スキップ"; return }

    Log "=== Claude Code 設定を復元 ==="
    $cliDst = Join-Path $env:USERPROFILE ".claude"
    if (-not (Test-Path $cliDst)) { New-Item -ItemType Directory -Path $cliDst | Out-Null }
    Copy-Item -Path "$claudeSrc\*" -Destination $cliDst -Recurse -Force
    Ok "  $claudeSrc → $cliDst 完了"

    $commandsDir = Join-Path $cliDst "commands"
    if (Test-Path $commandsDir) {
        $skillCount = (Get-ChildItem $commandsDir -Filter "*.md" -ErrorAction SilentlyContinue).Count
        Ok "  スキル $skillCount 個を復元"
    }
}

# ----------------------------
# 現在の環境をキャプチャしてGoogle Driveに保存
# ----------------------------
function Capture-Environment {
    Log "=== 現在の環境をキャプチャ ==="

    $pkgDir = Join-Path $GDrivePath "packages"
    if (-not (Test-Path $pkgDir)) { New-Item -ItemType Directory -Path $pkgDir | Out-Null }

    # npm グローバルパッケージ
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $outFile = Join-Path $pkgDir "npm-globals.txt"
        npm list -g --depth=0 --parseable 2>$null |
            Select-Object -Skip 1 |
            ForEach-Object { Split-Path $_ -Leaf } |
            Where-Object { $_ -ne "npm" } |
            Set-Content $outFile
        Ok "  npm-globals.txt → $outFile"
    }

    # pip パッケージ
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        $outFile = Join-Path $pkgDir "pip-requirements.txt"
        pip freeze --user > $outFile
        Ok "  pip-requirements.txt → $outFile"
    }

    # Claude Code 設定 (~/.claude)
    $claudeSrc = Join-Path $env:USERPROFILE ".claude"
    if (Test-Path $claudeSrc) {
        $claudeDst = Join-Path $GDrivePath ".claude"
        if (-not (Test-Path $claudeDst)) { New-Item -ItemType Directory -Path $claudeDst | Out-Null }
        Copy-Item -Path "$claudeSrc\*" -Destination $claudeDst -Recurse -Force
        Ok "  ~/.claude → $claudeDst 完了"
    }

    Ok "キャプチャ完了"
}

# ----------------------------
# Git の設定
# ----------------------------
function Setup-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Warn "git なし。スキップ"; return }
    Log "=== Git 設定 ==="
    $gitconfigLocal = Join-Path $env:USERPROFILE ".gitconfig.local"
    if (-not (Test-Path $gitconfigLocal)) {
        @"
# ~/.gitconfig.local - 個人情報はここに書く
[user]
    name = Your Name
    email = your@email.com
"@ | Set-Content $gitconfigLocal
        Warn "  $gitconfigLocal に名前とメールを設定してください"
    }
}

# ----------------------------
# メイン
# ----------------------------
function Main {
    Log "=== Windows セットアップ開始 ==="
    Log "Google Drive パス: $GDrivePath"
    Log ""

    if ($CaptureOnly) {
        Capture-Environment
        return
    }

    if (-not $SkipWinget) { Install-WingetPackages }

    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not $SkipNpm)    { Restore-NpmPackages }
    if (-not $SkipPip)    { Restore-PipPackages }
    if (-not $SkipClaude) { Restore-ClaudeSettings }

    Setup-Git

    Log ""
    Ok "=== セットアップ完了！ ==="
    Log ""
    Log "次のステップ:"
    Log "  1. ~/.gitconfig.local に名前・メールを設定"
    Log "  2. Claude Code を起動して動作確認"
    Log "  3. dotfiles リポジトリをクローン:"
    Log "     git clone https://github.com/shiitora/shiitora.git ~/dotfiles"
}

Main
