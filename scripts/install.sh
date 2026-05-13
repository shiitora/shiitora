#!/usr/bin/env bash
# dotfiles インストールスクリプト
# 使い方: ./scripts/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/..' && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
err()  { echo "[ERROR] $*" >&2; exit 1; }

backup_and_link() {
  local src="$1"
  local dst="$2"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    log "バックアップ: $dst → $BACKUP_DIR/"
  fi

  ln -sf "$src" "$dst"
  log "リンク作成: $dst → $src"
}

install_shell() {
  log "=== シェル設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/shell/bashrc"      "$HOME/.bashrc"
  backup_and_link "$DOTFILES_DIR/shell/bash_profile" "$HOME/.bash_profile"

  if [ ! -f "$HOME/.bashrc.local" ]; then
    cat > "$HOME/.bashrc.local" << 'EOF'
# ~/.bashrc.local - この端末固有の設定をここに書く
# このファイルはGit管理外です
EOF
    log "作成: ~/.bashrc.local"
  fi
}

install_git() {
  log "=== Git設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/git/gitconfig"        "$HOME/.gitconfig"
  backup_and_link "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true

  if [ ! -f "$HOME/.gitconfig.local" ]; then
    cat > "$HOME/.gitconfig.local" << 'EOF'
# ~/.gitconfig.local - 個人情報はここに書く (Git管理外)
[user]
	name = Your Name
	email = your@email.com
EOF
    warn "~/.gitconfig.local にあなたの名前とメールを設定してください"
  fi
}

install_vim() {
  log "=== Vim設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
  mkdir -p "$HOME/.vim/undo"
}

install_tmux() {
  log "=== Tmux設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
}

install_claude() {
  log "=== Claude Code設定のインストール ==="
  mkdir -p "$HOME/.claude"
  backup_and_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
}

main() {
  log "dotfiles のインストールを開始します"
  install_shell
  install_git
  install_vim
  install_tmux
  install_claude
  echo ""
  log "✓ インストール完了！"
  log "次のステップ:"
  log "  1. source ~/.bashrc"
  log "  2. ~/.gitconfig.local にあなたの名前・メールを設定"
  log "  3. ~/.bashrc.local に端末固有の設定を追加"
}

main "$@"
