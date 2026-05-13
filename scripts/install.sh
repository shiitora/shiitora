#!/usr/bin/env bash
# dotfiles インストールスクリプト
# 使い方: ./scripts/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ----------------------------
# ユーティリティ
# ----------------------------
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

# ----------------------------
# シェル設定
# ----------------------------
install_shell() {
  log "=== シェル設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/shell/bashrc"      "$HOME/.bashrc"
  backup_and_link "$DOTFILES_DIR/shell/bash_profile" "$HOME/.bash_profile"

  # ローカル設定ファイルが無ければ作成
  if [ ! -f "$HOME/.bashrc.local" ]; then
    cat > "$HOME/.bashrc.local" << 'EOF'
# ~/.bashrc.local - この端末固有の設定をここに書く
# このファイルはGit管理外です

# 例: 端末固有のPATH
# export PATH="$HOME/mytools/bin:$PATH"

# 例: 端末固有のエイリアス
# alias work='cd ~/workspace/myproject'
EOF
    log "作成: ~/.bashrc.local (端末固有の設定用)"
  fi
}

# ----------------------------
# Git設定
# ----------------------------
install_git() {
  log "=== Git設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/git/gitconfig"        "$HOME/.gitconfig"
  backup_and_link "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true

  # ローカル設定（名前・メール）が無ければ作成
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

# ----------------------------
# Vim設定
# ----------------------------
install_vim() {
  log "=== Vim設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

  # undoディレクトリ作成
  mkdir -p "$HOME/.vim/undo"
  log "作成: ~/.vim/undo"
}

# ----------------------------
# Tmux設定
# ----------------------------
install_tmux() {
  log "=== Tmux設定のインストール ==="
  backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
}

# ----------------------------
# Claude Code設定
# ----------------------------
install_claude() {
  log "=== Claude Code設定のインストール ==="
  mkdir -p "$HOME/.claude"
  backup_and_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
}

# ----------------------------
# メイン
# ----------------------------
main() {
  log "dotfiles のインストールを開始します"
  log "ソース: $DOTFILES_DIR"
  log "バックアップ先: $BACKUP_DIR"
  echo ""

  install_shell
  install_git
  install_vim
  install_tmux
  install_claude

  echo ""
  log "✓ インストール完了！"
  log ""
  log "次のステップ:"
  log "  1. source ~/.bashrc  (シェル設定を反映)"
  log "  2. ~/.gitconfig.local にあなたの名前・メールを設定"
  log "  3. ~/.bashrc.local に端末固有の設定を追加"
}

main "$@"
