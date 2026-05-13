#!/usr/bin/env bash
# 他の端末で実行するスクリプト: 現在の環境をキャプチャしてGoogle Driveに保存する
# 使い方: ./scripts/capture.sh
#
# 保存先 (Google Drive):
#   G:\packages\npm-globals.txt
#   G:\packages\pip-requirements.txt
#   G:\packages\apt-packages.txt
#   G:\.claude\   (そのままミラーリング)

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

RCLONE_REMOTE="gdrive"
GDRIVE_PACKAGES="${RCLONE_REMOTE}:packages"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

check_rclone() {
  command -v rclone &>/dev/null || { warn "rclone 未インストール"; exit 1; }
  rclone listremotes | grep -q "^${RCLONE_REMOTE}:" || { warn "gdrive 未設定。rclone config で設定してください"; exit 1; }
}

capture_npm() {
  if ! command -v npm &>/dev/null; then warn "npm なし。スキップ"; return; fi
  log "npm グローバルパッケージをキャプチャ中..."
  npm list -g --depth=0 --parseable 2>/dev/null \
    | tail -n +2 \
    | xargs -I{} basename {} \
    | grep -v '^npm$' \
    > "$TMP_DIR/npm-globals.txt"
  log "  $(wc -l < "$TMP_DIR/npm-globals.txt") パッケージ"
}

capture_pip() {
  if ! command -v pip3 &>/dev/null; then warn "pip3 なし。スキップ"; return; fi
  log "pip パッケージをキャプチャ中..."
  pip3 freeze --user > "$TMP_DIR/pip-requirements.txt"
  log "  $(wc -l < "$TMP_DIR/pip-requirements.txt") パッケージ"
}

capture_apt() {
  if ! command -v apt-mark &>/dev/null; then warn "apt なし。スキップ"; return; fi
  log "apt パッケージをキャプチャ中..."
  apt-mark showmanual > "$TMP_DIR/apt-packages.txt"
  log "  $(wc -l < "$TMP_DIR/apt-packages.txt") パッケージ"
}

capture_go() {
  if ! command -v go &>/dev/null; then warn "go なし。スキップ"; return; fi
  log "Go ツールをキャプチャ中..."
  find "$(go env GOPATH)/bin" -maxdepth 1 -type f -executable 2>/dev/null \
    | xargs -I{} basename {} \
    > "$TMP_DIR/go-tools.txt" 2>/dev/null || true
  log "  $(wc -l < "$TMP_DIR/go-tools.txt") ツール"
}

capture_claude() {
  if [ ! -d "$HOME/.claude" ]; then warn "~/.claude なし。スキップ"; return; fi
  log "Claude Code 設定をGoogle Driveに同期中..."
  rclone sync "$HOME/.claude" "${RCLONE_REMOTE}:.claude" \
    --exclude "session.log" \
    --exclude "*.tmp" \
    --progress
  log "  ~/.claude → gdrive:.claude 完了"
}

upload_packages() {
  log "パッケージ一覧を Google Drive にアップロード中..."
  rclone copy "$TMP_DIR" "$GDRIVE_PACKAGES" --progress
  log "  完了: ${GDRIVE_PACKAGES}/"
}

main() {
  log "=== 環境キャプチャ開始 ==="
  check_rclone
  capture_npm
  capture_pip
  capture_apt
  capture_go
  capture_claude
  upload_packages
  echo ""
  log "✓ キャプチャ完了！"
  log "同期先のLinuxで以下を実行してください:"
  log "  ./scripts/restore.sh"
}

main "$@"
