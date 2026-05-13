#!/usr/bin/env bash
# Google Drive 同期スクリプト (rclone使用)
# Google Drive の内容をローカルとミラーリングする
#
# 前提:
#   - rclone がインストール済み
#   - rclone に "gdrive" という名前でGoogle Driveを設定済み
#     設定方法: rclone config → "gdrive" の名前でGoogle Driveを追加
#
# Google Drive上のパス構成 (Windows C:\G\ 配下):
#   G:\.claude\   →  ~/.claude/
#
# 使い方:
#   ./scripts/gdrive-sync.sh          # Google Drive → ローカル (pull)
#   ./scripts/gdrive-sync.sh push     # ローカル → Google Drive (push)
#   ./scripts/gdrive-sync.sh both     # 双方向 (pull → push)
#   ./scripts/gdrive-sync.sh install  # rclone のインストール

set -euo pipefail

# ----------------------------
# 設定
# ----------------------------
RCLONE_REMOTE="gdrive"           # rclone config で設定したリモート名
GDRIVE_BASE=""                   # Google Drive上のベースパス (空=ルート)
LOCAL_BASE="$HOME"               # ローカルのベースパス

# 同期対象: "Google Drive上のパス" → "ローカルパス"
declare -A SYNC_TARGETS=(
  [".claude"]=".claude"          # G:\.claude → ~/.claude
)

# ----------------------------
# ユーティリティ
# ----------------------------
log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
err()  { echo "[ERROR] $*" >&2; exit 1; }

check_rclone() {
  if ! command -v rclone &>/dev/null; then
    err "rclone が見つかりません。'$0 install' でインストールしてください。"
  fi
  if ! rclone listremotes 2>/dev/null | grep -q "^${RCLONE_REMOTE}:"; then
    err "rcloneリモート '${RCLONE_REMOTE}' が未設定です。\n  設定方法: rclone config\n  名前: ${RCLONE_REMOTE}  種類: drive"
  fi
}

gdrive_path() {
  local relative="$1"
  if [ -n "$GDRIVE_BASE" ]; then
    echo "${RCLONE_REMOTE}:${GDRIVE_BASE}/${relative}"
  else
    echo "${RCLONE_REMOTE}:${relative}"
  fi
}

# ----------------------------
# pull: Google Drive → ローカル
# ----------------------------
do_pull() {
  log "=== Google Drive → ローカル (pull) ==="
  for gdrive_rel in "${!SYNC_TARGETS[@]}"; do
    local local_rel="${SYNC_TARGETS[$gdrive_rel]}"
    local src
    src=$(gdrive_path "$gdrive_rel")
    local dst="${LOCAL_BASE}/${local_rel}"

    log "同期: ${src} → ${dst}"
    mkdir -p "$dst"
    rclone sync "$src" "$dst" \
      --progress \
      --exclude "*.tmp" \
      --exclude ".DS_Store"
  done
  log "✓ pull 完了"
}

# ----------------------------
# push: ローカル → Google Drive
# ----------------------------
do_push() {
  log "=== ローカル → Google Drive (push) ==="
  for gdrive_rel in "${!SYNC_TARGETS[@]}"; do
    local local_rel="${SYNC_TARGETS[$gdrive_rel]}"
    local src="${LOCAL_BASE}/${local_rel}"
    local dst
    dst=$(gdrive_path "$gdrive_rel")

    if [ ! -d "$src" ]; then
      warn "存在しないため スキップ: $src"
      continue
    fi

    log "同期: ${src} → ${dst}"
    rclone sync "$src" "$dst" \
      --progress \
      --exclude "*.tmp" \
      --exclude ".DS_Store"
  done
  log "✓ push 完了"
}

# ----------------------------
# rclone インストール
# ----------------------------
do_install() {
  log "=== rclone のインストール ==="
  if command -v rclone &>/dev/null; then
    log "rclone はすでにインストールされています: $(rclone version | head -1)"
    return
  fi

  curl -fsSL https://rclone.org/install.sh | sudo bash
  log "✓ rclone インストール完了"
  echo ""
  log "次に Google Drive を設定してください:"
  log "  rclone config"
  log "  → n (新規) → 名前: gdrive → 種類: drive → ブラウザで認証"
}

# ----------------------------
# 設定確認
# ----------------------------
do_status() {
  log "=== 設定確認 ==="
  if command -v rclone &>/dev/null; then
    log "rclone: $(rclone version | head -1)"
    log "設定済みリモート:"
    rclone listremotes | sed 's/^/  /'
  else
    warn "rclone 未インストール"
  fi

  echo ""
  log "同期対象:"
  for gdrive_rel in "${!SYNC_TARGETS[@]}"; do
    local local_rel="${SYNC_TARGETS[$gdrive_rel]}"
    local gdrive_full
    gdrive_full=$(gdrive_path "$gdrive_rel")
    log "  ${gdrive_full} ↔ ${LOCAL_BASE}/${local_rel}"
  done
}

# ----------------------------
# メイン
# ----------------------------
main() {
  local cmd="${1:-pull}"

  case "$cmd" in
    pull)
      check_rclone
      do_pull
      ;;
    push)
      check_rclone
      do_push
      ;;
    both)
      check_rclone
      do_pull
      do_push
      ;;
    install)
      do_install
      ;;
    status)
      do_status
      ;;
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
