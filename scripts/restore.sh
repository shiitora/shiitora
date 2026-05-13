#!/usr/bin/env bash
# このLinux端末でGoogle Driveから取得したパッケージ一覧を元に環境を復元する
# 使い方: ./scripts/restore.sh [all|npm|pip|apt|claude]

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

RCLONE_REMOTE="gdrive"
GDRIVE_PACKAGES="${RCLONE_REMOTE}:packages"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fetch_package_lists() {
  log "=== Google Drive からパッケージ一覧を取得 ==="
  command -v rclone &>/dev/null || { warn "rclone 未インストール。./scripts/gdrive-sync.sh install を実行してください。"; exit 1; }
  rclone copy "$GDRIVE_PACKAGES" "$TMP_DIR" --progress 2>/dev/null || {
    warn "Google Drive にパッケージ一覧がありません。"
    warn "ソース端末で ./scripts/capture.sh を先に実行してください。"
    exit 1
  }
}

restore_npm() {
  local list="$TMP_DIR/npm-globals.txt"
  [ -f "$list" ] || { warn "npm-globals.txt なし。スキップ"; return; }
  command -v npm &>/dev/null || { warn "npm なし。スキップ"; return; }
  log "=== npm グローバルパッケージをインストール ==="
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    log "  $pkg"
    npm install -g "$pkg" 2>/dev/null || warn "  失敗: $pkg"
  done < "$list"
}

restore_pip() {
  local list="$TMP_DIR/pip-requirements.txt"
  [ -f "$list" ] || { warn "pip-requirements.txt なし。スキップ"; return; }
  command -v pip3 &>/dev/null || { warn "pip3 なし。スキップ"; return; }
  log "=== pip パッケージをインストール ==="
  pip3 install --user -r "$list" || warn "一部パッケージのインストールに失敗しました"
}

restore_apt() {
  local list="$TMP_DIR/apt-packages.txt"
  [ -f "$list" ] || { warn "apt-packages.txt なし。スキップ"; return; }
  command -v apt-get &>/dev/null || { warn "apt-get なし。スキップ"; return; }
  log "=== apt パッケージをインストール ==="
  sudo apt-get update -q
  xargs -a "$list" sudo apt-get install -y 2>/dev/null || warn "一部パッケージのインストールに失敗しました"
}

restore_claude() {
  log "=== Claude Code 設定を同期 ==="
  command -v rclone &>/dev/null || { warn "rclone なし。スキップ"; return; }
  rclone listremotes | grep -q "^${RCLONE_REMOTE}:" || { warn "gdrive 未設定。スキップ"; return; }
  mkdir -p "$HOME/.claude/commands"
  rclone sync "${RCLONE_REMOTE}:.claude" "$HOME/.claude" \
    --exclude "session.log" \
    --progress
  log "  gdrive:.claude → ~/.claude 完了"
  log "  スキル (slash commands) も同期されました"
}

main() {
  local target="${1:-all}"
  case "$target" in
    npm)    fetch_package_lists; restore_npm ;;
    pip)    fetch_package_lists; restore_pip ;;
    apt)    fetch_package_lists; restore_apt ;;
    claude) restore_claude ;;
    all)
      fetch_package_lists
      restore_npm
      restore_pip
      restore_apt
      restore_claude
      ;;
    *) echo "使い方: $0 [all|npm|pip|apt|claude]"; exit 1 ;;
  esac
  echo ""
  log "✓ 復元完了！"
}

main "$@"
