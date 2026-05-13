#!/usr/bin/env bash
# capture.sh - 現在の環境をGoogle Driveに保存
# 使い方: ./scripts/capture.sh [all|npm|pip|apt|claude|history|memory|mcp]

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

RCLONE_REMOTE="gdrive"
GDRIVE_PACKAGES="${RCLONE_REMOTE}:packages"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

check_rclone() {
  command -v rclone &>/dev/null || { warn "rclone 未インストール"; exit 1; }
  rclone listremotes | grep -q "^${RCLONE_REMOTE}:" || {
    warn "gdrive 未設定。rclone config で設定してください"
    exit 1
  }
}

capture_npm() {
  if ! command -v npm &>/dev/null; then warn "npm なし。スキップ"; return; fi
  log "npm グローバルパッケージをキャプチャ中..."
  npm list -g --depth=0 --parseable 2>/dev/null \
    | tail -n +2 | xargs -I{} basename {} | grep -v '^npm$' \
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

capture_claude() {
  if [ ! -d "$HOME/.claude" ]; then warn "~/.claude なし。スキップ"; return; fi
  log "Claude Code 設定・スキル・プラグイン設定を同期中..."
  rclone sync "$HOME/.claude" "${RCLONE_REMOTE}:.claude" \
    --exclude ".credentials.json" \
    --exclude "session.log" \
    --exclude "*.tmp" \
    --exclude "shell-snapshots/**" \
    --exclude "uploads/**" \
    --exclude "projects/**" \
    --exclude "session-env/**" \
    --exclude "sessions/**" \
    --progress
  log "  ~/.claude → gdrive:.claude 完了 (履歴・認証情報除く)"
}

capture_history() {
  if [ ! -d "$HOME/.claude/projects" ]; then warn "会話履歴なし。スキップ"; return; fi
  log "Claude Code 会話履歴を同期中..."
  rclone sync "$HOME/.claude/projects" "${RCLONE_REMOTE}:.claude/projects" \
    --progress
  local count
  count=$(find "$HOME/.claude/projects" -name "*.jsonl" 2>/dev/null | wc -l)
  log "  $count セッションファイル同期完了"
}

capture_memory() {
  log "Claude Code メモリを同期中..."
  # グローバルメモリ (~/.claude/CLAUDE.md)
  if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    rclone copy "$HOME/.claude/CLAUDE.md" "${RCLONE_REMOTE}:.claude/" --progress
    log "  ~/.claude/CLAUDE.md → gdrive:.claude/ 完了"
  else
    warn "  ~/.claude/CLAUDE.md なし。スキップ"
  fi
  # プロジェクトメモリ (各プロジェクトの CLAUDE.md)
  # ※ プロジェクト単位のメモリは projects/ に含まれる
}

capture_mcp() {
  log "MCP サーバー設定を同期中..."
  # MCP設定はsettings.jsonまたはmcp.jsonに格納
  local synced=0
  for f in "$HOME/.claude/mcp.json" "$HOME/.claude/mcp_servers.json"; do
    if [ -f "$f" ]; then
      rclone copy "$f" "${RCLONE_REMOTE}:.claude/" --progress
      log "  $(basename $f) → gdrive:.claude/ 完了"
      synced=$((synced + 1))
    fi
  done
  # settings.jsonのmcpServersセクションも含まれるため
  if [ -f "$HOME/.claude/settings.json" ]; then
    log "  settings.json (MCP設定含む) は claude キャプチャで同期済み"
    synced=$((synced + 1))
  fi
  [ $synced -eq 0 ] && warn "  MCP設定ファイルなし" || true
}

upload_packages() {
  log "パッケージ一覧を Google Drive にアップロード中..."
  rclone copy "$TMP_DIR" "$GDRIVE_PACKAGES" --progress
  log "  完了: ${GDRIVE_PACKAGES}/"
}

main() {
  local target="${1:-all}"
  log "=== 環境キャプチャ開始 (${target}) ==="
  check_rclone

  case "$target" in
    npm)     capture_npm; upload_packages ;;
    pip)     capture_pip; upload_packages ;;
    apt)     capture_apt; upload_packages ;;
    claude)  capture_claude ;;
    history) capture_history ;;
    memory)  capture_memory ;;
    mcp)     capture_mcp ;;
    all)
      capture_npm
      capture_pip
      capture_apt
      upload_packages
      capture_claude
      capture_history
      capture_memory
      capture_mcp
      ;;
    *) echo "使い方: $0 [all|npm|pip|apt|claude|history|memory|mcp]"; exit 1 ;;
  esac

  echo ""
  log "✓ キャプチャ完了！"
  log "復元先で: ./scripts/restore.sh"
}

main "$@"
