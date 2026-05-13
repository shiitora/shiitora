#!/usr/bin/env bash
# setup-new-linux.sh
# Linux 新規PC セットアップスクリプト (setup-new-pc.ps1 の Linux 版)
# 使い方:
#   git clone https://github.com/shiitora/shiitora.git ~/dotfiles
#   cd ~/dotfiles
#   ./scripts/setup-new-linux.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
ok()   { echo "[OK]    $*"; }

# ----------------------------
# オプション解析
# ----------------------------
SKIP_APT=false
SKIP_NODE=false
SKIP_NPM=false
SKIP_PIP=false
SKIP_CLAUDE=false
SKIP_GDRIVE=false

for arg in "$@"; do
  case "$arg" in
    --skip-apt)    SKIP_APT=true ;;
    --skip-node)   SKIP_NODE=true ;;
    --skip-npm)    SKIP_NPM=true ;;
    --skip-pip)    SKIP_PIP=true ;;
    --skip-claude) SKIP_CLAUDE=true ;;
    --skip-gdrive) SKIP_GDRIVE=true ;;
    --help|-h)
      echo "使い方: $0 [オプション]"
      echo ""
      echo "オプション:"
      echo "  --skip-apt     apt パッケージをスキップ"
      echo "  --skip-node    Node.js (nvm) インストールをスキップ"
      echo "  --skip-npm     npm グローバルパッケージをスキップ"
      echo "  --skip-pip     pip パッケージをスキップ"
      echo "  --skip-claude  Claude Code プラグインをスキップ"
      echo "  --skip-gdrive  Google Drive からの復元をスキップ"
      exit 0
      ;;
  esac
done

# ----------------------------
# apt パッケージ
# ----------------------------
install_apt() {
  log "=== apt パッケージのインストール ==="
  if ! command -v apt-get &>/dev/null; then warn "apt-get なし。スキップ"; return; fi

  sudo apt-get update -q
  sudo apt-get install -y \
    curl wget git vim tmux make build-essential unzip jq tree \
    ripgrep fd-find bat rclone \
    python3 python3-pip python3-venv \
    net-tools dnsutils
  ok "apt 完了"
}

# ----------------------------
# Node.js (nvm)
# ----------------------------
install_node() {
  log "=== Node.js (nvm) のインストール ==="
  if command -v node &>/dev/null; then
    log "node すでに存在: $(node --version)。スキップ"
    return
  fi

  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
  ok "Node.js $(node --version) インストール完了"
}

# ----------------------------
# Claude Code
# ----------------------------
install_claude_code() {
  log "=== Claude Code のインストール ==="
  if command -v claude &>/dev/null; then
    log "claude すでに存在: $(claude --version)。スキップ"
    return
  fi
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code インストール完了"
}

# ----------------------------
# dotfiles シンボリックリンク
# ----------------------------
install_dotfiles() {
  log "=== dotfiles のインストール ==="
  "$DOTFILES_DIR/scripts/install.sh"
  ok "dotfiles 完了"
}

# ----------------------------
# npm グローバルパッケージ
# ----------------------------
install_npm() {
  log "=== npm グローバルパッケージのインストール ==="
  if ! command -v npm &>/dev/null; then warn "npm なし。スキップ"; return; fi

  for pkg in typescript ts-node prettier eslint; do
    npm install -g "$pkg" 2>/dev/null || warn "失敗: $pkg"
  done
  ok "npm 完了"
}

# ----------------------------
# pip パッケージ
# ----------------------------
install_pip() {
  log "=== pip パッケージのインストール ==="
  if ! command -v pip3 &>/dev/null; then warn "pip3 なし。スキップ"; return; fi

  pip3 install --user black isort flake8 mypy ipython httpx rich anthropic
  ok "pip 完了"
}

# ----------------------------
# Claude Code プラグイン
# ----------------------------
install_claude_plugins() {
  log "=== Claude Code プラグインのインストール ==="
  if ! command -v claude &>/dev/null; then warn "claude なし。スキップ"; return; fi

  # マーケットプレイス登録
  local marketplaces=(
    "InterfaceX-co-jp/genshijin"
    "obra/superpowers-marketplace"
    "anthropics/skills"
    "lackeyjb/playwright-skill"
    "tw93/claude-health"
  )
  for mp in "${marketplaces[@]}"; do
    claude plugin marketplace add "$mp" 2>/dev/null && log "  マーケットプレイス追加: $mp" || warn "  スキップ (登録済み): $mp"
  done

  # プラグインインストール
  local plugins=(
    "genshijin@genshijin"
    "superpowers@superpowers-marketplace"
    "superpowers-dev@superpowers-marketplace"
    "claude-session-driver@superpowers-marketplace"
    "document-skills@anthropic-agent-skills"
    "playwright-skill@playwright-skill"
  )
  for plugin in "${plugins[@]}"; do
    claude plugin install "$plugin" 2>/dev/null && ok "  $plugin" || warn "  スキップ: $plugin"
  done

  # スキル (slash commands) をコピー
  mkdir -p "$HOME/.claude/commands"
  if [ -d "$DOTFILES_DIR/claude/commands" ]; then
    cp "$DOTFILES_DIR/claude/commands/"*.md "$HOME/.claude/commands/" 2>/dev/null || true
    ok "  スキル $(ls "$DOTFILES_DIR/claude/commands/"*.md 2>/dev/null | wc -l) 個をインストール"
  fi

  ok "Claude Code プラグイン完了"
}

# ----------------------------
# Google Drive から環境復元
# ----------------------------
restore_from_gdrive() {
  log "=== Google Drive から環境を復元 ==="
  if ! command -v rclone &>/dev/null; then
    warn "rclone なし。スキップ (./scripts/gdrive-sync.sh install でインストール可能)"
    return
  fi
  if ! rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
    warn "rclone の gdrive 未設定。スキップ"
    warn "設定方法: rclone config → 名前: gdrive → 種類: drive"
    return
  fi

  "$DOTFILES_DIR/scripts/restore.sh" all
  ok "Google Drive 復元完了"
}

# ----------------------------
# Git 設定
# ----------------------------
setup_git() {
  log "=== Git 設定 ==="
  if [ ! -f "$HOME/.gitconfig.local" ]; then
    warn "~/.gitconfig.local に名前とメールを設定してください:"
    warn "  git config -f ~/.gitconfig.local user.name  '名前'"
    warn "  git config -f ~/.gitconfig.local user.email 'メール'"
  else
    ok "~/.gitconfig.local 存在確認"
  fi
}

# ----------------------------
# メイン
# ----------------------------
main() {
  log "=== Linux セットアップ開始 ==="
  log "dotfiles: $DOTFILES_DIR"
  echo ""

  $SKIP_APT    || install_apt
  $SKIP_NODE   || install_node
  install_claude_code
  install_dotfiles

  # PATH を再読み込み
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  $SKIP_NPM    || install_npm
  $SKIP_PIP    || install_pip
  $SKIP_CLAUDE || install_claude_plugins
  $SKIP_GDRIVE || restore_from_gdrive

  setup_git

  echo ""
  ok "=== セットアップ完了！ ==="
  echo ""
  log "次のステップ:"
  log "  1. source ~/.bashrc  (シェル設定を反映)"
  log "  2. ~/.gitconfig.local に名前・メールを設定"
  log "  3. claude を起動してプラグインを確認"
}

main "$@"
