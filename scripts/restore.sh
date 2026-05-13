#!/usr/bin/env bash
# restore.sh - Google Driveから環境を復元
# 使い方: ./scripts/restore.sh [all|npm|pip|apt|claude|history|memory|mcp]

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

RCLONE_REMOTE="gdrive"
GDRIVE_PACKAGES="${RCLONE_REMOTE}:packages"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

check_rclone() {
  command -v rclone &>/dev/null || {
    warn "rclone 未インストール。./scripts/gdrive-sync.sh install を実行してください"
    exit 1
  }
  rclone listremotes | grep -q "^${RCLONE_REMOTE}:" || {
    warn "gdrive 未設定。rclone config で設定してください"
    exit 1
  }
}

fetch_packages() {
  log "パッケージ一覧を Google Drive から取得中..."
  rclone copy "$GDRIVE_PACKAGES" "$TMP_DIR" --progress 2>/dev/null || {
    warn "Google Drive にパッケージ一覧がありません"
    warn "ソース端末で ./scripts/capture.sh を先に実行してください"
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
  log "=== Claude Code 設定・スキル・プラグイン設定を同期 ==="
  mkdir -p "$HOME/.claude/commands"
  rclone sync "${RCLONE_REMOTE}:.claude" "$HOME/.claude" \
    --exclude ".credentials.json" \
    --exclude "projects/**" \
    --exclude "session-env/**" \
    --exclude "sessions/**" \
    --progress
  log "  gdrive:.claude → ~/.claude 完了"
  local skill_count
  skill_count=$(find "$HOME/.claude/commands" -name "*.md" 2>/dev/null | wc -l)
  log "  スキル ${skill_count} 個同期完了"
}

restore_history() {
  log "=== Claude Code 会話履歴を同期 ==="
  mkdir -p "$HOME/.claude/projects"
  rclone sync "${RCLONE_REMOTE}:.claude/projects" "$HOME/.claude/projects" \
    --progress
  local count
  count=$(find "$HOME/.claude/projects" -name "*.jsonl" 2>/dev/null | wc -l)
  log "  $count セッションファイル復元完了"
  if [ $count -gt 0 ]; then
    warn "  ※ 他OS (Windows等) からの履歴はパス表示が異なる場合があります"
  fi
}

restore_memory() {
  log "=== Claude Code メモリを同期 ==="
  if rclone ls "${RCLONE_REMOTE}:.claude/CLAUDE.md" &>/dev/null; then
    rclone copy "${RCLONE_REMOTE}:.claude/CLAUDE.md" "$HOME/.claude/" --progress
    log "  グローバルメモリ (CLAUDE.md) 復元完了"
  else
    warn "  gdrive:.claude/CLAUDE.md なし。スキップ"
  fi
}

restore_mcp() {
  log "=== MCP サーバー設定を同期 ==="
  for f in mcp.json mcp_servers.json; do
    if rclone ls "${RCLONE_REMOTE}:.claude/${f}" &>/dev/null; then
      rclone copy "${RCLONE_REMOTE}:.claude/${f}" "$HOME/.claude/" --progress
      log "  ${f} 復元完了"
    fi
  done
  log "  MCP設定は settings.json にも含まれています (claude で同期済み)"
}

install_claude_plugins() {
  log "=== Claude Code プラグインをインストール ==="
  command -v claude &>/dev/null || { warn "claude なし。スキップ"; return; }

  local marketplaces=(
    "InterfaceX-co-jp/genshijin"
    "obra/superpowers-marketplace"
    "anthropics/skills"
    "lackeyjb/playwright-skill"
    "tw93/claude-health"
  )
  for mp in "${marketplaces[@]}"; do
    claude plugin marketplace add "$mp" 2>/dev/null || true
  done

  local plugins=(
    "genshijin@genshijin"
    "superpowers@superpowers-marketplace"
    "superpowers-dev@superpowers-marketplace"
    "claude-session-driver@superpowers-marketplace"
    "document-skills@anthropic-agent-skills"
    "playwright-skill@playwright-skill"
  )
  for plugin in "${plugins[@]}"; do
    claude plugin install "$plugin" 2>/dev/null && log "  ✓ $plugin" || true
  done
}

main() {
  local target="${1:-all}"
  log "=== 環境復元開始 (${target}) ==="
  check_rclone

  case "$target" in
    npm)     fetch_packages; restore_npm ;;
    pip)     fetch_packages; restore_pip ;;
    apt)     fetch_packages; restore_apt ;;
    claude)  restore_claude; install_claude_plugins ;;
    history) restore_history ;;
    memory)  restore_memory ;;
    mcp)     restore_mcp ;;
    all)
      fetch_packages
      restore_npm
      restore_pip
      restore_apt
      restore_claude
      restore_history
      restore_memory
      restore_mcp
      install_claude_plugins
      ;;
    *) echo "使い方: $0 [all|npm|pip|apt|claude|history|memory|mcp]"; exit 1 ;;
  esac

  echo ""
  log "✓ 復元完了！"
  [ "$target" = "all" ] || [ "$target" = "claude" ] && \
    log "Claude Code を再起動するとスキル・プラグインが有効になります"
  return 0
}

main "$@"
