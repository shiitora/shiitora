#!/usr/bin/env bash
# gdrive-sync.sh - Google Drive ↔ ローカル ミラーリング (rclone使用)
# 使い方:
#   ./scripts/gdrive-sync.sh          # Google Drive → ローカル (pull)
#   ./scripts/gdrive-sync.sh push     # ローカル → Google Drive (push)
#   ./scripts/gdrive-sync.sh both     # 双方向 (pull → push)
#   ./scripts/gdrive-sync.sh install  # rclone インストール
#   ./scripts/gdrive-sync.sh status   # 設定確認

set -euo pipefail

RCLONE_REMOTE="gdrive"
LOCAL_BASE="$HOME"

# 同期対象: "Google Drive上のパス" → "ローカルパス"
declare -A SYNC_TARGETS=(
  [".claude/commands"]=".claude/commands"          # スキル
  [".claude/settings.json"]=".claude/settings.json" # 設定
  [".claude/projects"]=".claude/projects"          # 会話履歴
  [".claude/CLAUDE.md"]=".claude/CLAUDE.md"        # グローバルメモリ
)

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
err()  { echo "[ERROR] $*" >&2; exit 1; }

check_rclone() {
  command -v rclone &>/dev/null || err "rclone が見つかりません。'$0 install' でインストールしてください。"
  rclone listremotes 2>/dev/null | grep -q "^${RCLONE_REMOTE}:" || \
    err "rcloneリモート '${RCLONE_REMOTE}' が未設定です。\n  設定方法: rclone config\n  名前: ${RCLONE_REMOTE}  種類: drive"
}

do_pull() {
  log "=== Google Drive → ローカル (pull) ==="
  # .claude 全体を同期 (認証情報・一時ファイル除く)
  mkdir -p "$LOCAL_BASE/.claude"
  rclone sync "${RCLONE_REMOTE}:.claude" "$LOCAL_BASE/.claude" \
    --exclude ".credentials.json" \
    --exclude "*.tmp" \
    --exclude "shell-snapshots/**" \
    --exclude "uploads/**" \
    --progress
  log "✓ pull 完了"
}

do_push() {
  log "=== ローカル → Google Drive (push) ==="
  if [ ! -d "$LOCAL_BASE/.claude" ]; then
    warn "$LOCAL_BASE/.claude が存在しません。スキップ"
    return
  fi
  rclone sync "$LOCAL_BASE/.claude" "${RCLONE_REMOTE}:.claude" \
    --exclude ".credentials.json" \
    --exclude "*.tmp" \
    --exclude "shell-snapshots/**" \
    --exclude "uploads/**" \
    --exclude "session-env/**" \
    --exclude "sessions/**" \
    --progress
  log "✓ push 完了"
}

do_install() {
  log "=== rclone のインストール ==="
  if command -v rclone &>/dev/null; then
    log "rclone はすでにインストールされています: $(rclone version | head -1)"
    return
  fi
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -q && sudo apt-get install -y rclone
  else
    curl -fsSL https://rclone.org/install.sh | sudo bash
  fi
  log "✓ rclone インストール完了"
  echo ""
  log "次に Google Drive を設定してください:"
  log "  rclone config"
  log "  → n (新規) → 名前: gdrive → 種類: drive → ブラウザで認証"
}

do_status() {
  log "=== 設定確認 ==="
  if command -v rclone &>/dev/null; then
    log "rclone: $(rclone version | head -1)"
    log "設定済みリモート:"
    rclone listremotes | sed 's/^/  /' || echo "  (なし)"
  else
    warn "rclone 未インストール"
  fi
  echo ""
  log "同期対象: ${RCLONE_REMOTE}:.claude ↔ ~/.claude"
  log "  (認証情報・一時ファイル・セッションデータ除く)"
}

main() {
  local cmd="${1:-pull}"
  case "$cmd" in
    pull)    check_rclone; do_pull ;;
    push)    check_rclone; do_push ;;
    both)    check_rclone; do_pull; do_push ;;
    install) do_install ;;
    status)  do_status ;;
    *)
      echo "使い方: $0 [pull|push|both|install|status]"
      echo ""
      echo "  pull    Google Drive → ローカルにミラーリング"
      echo "  push    ローカル → Google Driveにミラーリング"
      echo "  both    双方向同期 (pull → push)"
      echo "  install rclone をインストール"
      echo "  status  設定確認"
      exit 1
      ;;
  esac
}

main "$@"
