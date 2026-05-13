#!/usr/bin/env bash
# 必要なパッケージ・ツールのインストールスクリプト
# 使い方: ./scripts/packages.sh

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

# ----------------------------
# apt パッケージ
# ----------------------------
APT_PACKAGES=(
  # 基本ツール
  curl
  wget
  git
  vim
  tmux
  make
  build-essential
  unzip
  jq
  tree
  ripgrep
  fd-find
  bat
  # 開発ツール
  python3
  python3-pip
  python3-venv
  # ネットワーク
  net-tools
  dnsutils
  httpie
)

install_apt_packages() {
  log "=== apt パッケージのインストール ==="
  if ! command -v apt-get &>/dev/null; then
    warn "apt-get が見つかりません。スキップします。"
    return
  fi

  sudo apt-get update -q
  sudo apt-get install -y "${APT_PACKAGES[@]}"
  log "apt パッケージのインストール完了"
}

# ----------------------------
# Node.js / npm グローバルパッケージ
# ----------------------------
NPM_GLOBAL_PACKAGES=(
  typescript
  ts-node
  @anthropic-ai/claude-code
  prettier
  eslint
)

install_npm_packages() {
  log "=== npm グローバルパッケージのインストール ==="
  if ! command -v npm &>/dev/null; then
    warn "npm が見つかりません。スキップします。"
    return
  fi

  for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do
    npm install -g "$pkg" || warn "インストール失敗: $pkg"
  done
  log "npm グローバルパッケージのインストール完了"
}

# ----------------------------
# Python pip パッケージ
# ----------------------------
PIP_PACKAGES=(
  black
  isort
  flake8
  mypy
  ipython
  httpx
  rich
  anthropic
)

install_pip_packages() {
  log "=== pip パッケージのインストール ==="
  if ! command -v pip3 &>/dev/null; then
    warn "pip3 が見つかりません。スキップします。"
    return
  fi

  pip3 install --user "${PIP_PACKAGES[@]}"
  log "pip パッケージのインストール完了"
}

# ----------------------------
# Go ツール
# ----------------------------
GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
)

install_go_tools() {
  log "=== Go ツールのインストール ==="
  if ! command -v go &>/dev/null; then
    warn "go が見つかりません。スキップします。"
    return
  fi

  for tool in "${GO_TOOLS[@]}"; do
    go install "$tool" || warn "インストール失敗: $tool"
  done
  log "Go ツールのインストール完了"
}

# ----------------------------
# Rust / Cargo ツール
# ----------------------------
CARGO_TOOLS=(
  "cargo-watch"
  "cargo-edit"
)

install_cargo_tools() {
  log "=== Cargo ツールのインストール ==="
  if ! command -v cargo &>/dev/null; then
    warn "cargo が見つかりません。スキップします。"
    return
  fi

  for tool in "${CARGO_TOOLS[@]}"; do
    cargo install "$tool" || warn "インストール失敗: $tool"
  done
  log "Cargo ツールのインストール完了"
}

# ----------------------------
# メイン
# ----------------------------
main() {
  log "パッケージのインストールを開始します"

  local targets="${1:-all}"

  case "$targets" in
    apt)   install_apt_packages ;;
    npm)   install_npm_packages ;;
    pip)   install_pip_packages ;;
    go)    install_go_tools ;;
    cargo) install_cargo_tools ;;
    all)
      install_apt_packages
      install_npm_packages
      install_pip_packages
      install_go_tools
      install_cargo_tools
      ;;
    *)
      echo "使い方: $0 [all|apt|npm|pip|go|cargo]"
      exit 1
      ;;
  esac

  echo ""
  log "✓ 完了！"
}

main "$@"
