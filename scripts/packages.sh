#!/usr/bin/env bash
# 必要なパッケージ・ツールのインストールスクリプト
# 使い方: ./scripts/packages.sh [all|apt|npm|pip|go|cargo]

set -euo pipefail

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }

APT_PACKAGES=(
  curl wget git vim tmux make build-essential unzip jq tree
  ripgrep fd-find bat python3 python3-pip python3-venv
  net-tools dnsutils httpie
)

NPM_GLOBAL_PACKAGES=(typescript ts-node @anthropic-ai/claude-code prettier eslint)

PIP_PACKAGES=(black isort flake8 mypy ipython httpx rich anthropic)

GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
  "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
)

CARGO_TOOLS=(cargo-watch cargo-edit)

install_apt_packages() {
  command -v apt-get &>/dev/null || { warn "apt-get なし。スキップ"; return; }
  sudo apt-get update -q && sudo apt-get install -y "${APT_PACKAGES[@]}"
}

install_npm_packages() {
  command -v npm &>/dev/null || { warn "npm なし。スキップ"; return; }
  for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do npm install -g "$pkg" || warn "失敗: $pkg"; done
}

install_pip_packages() {
  command -v pip3 &>/dev/null || { warn "pip3 なし。スキップ"; return; }
  pip3 install --user "${PIP_PACKAGES[@]}"
}

install_go_tools() {
  command -v go &>/dev/null || { warn "go なし。スキップ"; return; }
  for tool in "${GO_TOOLS[@]}"; do go install "$tool" || warn "失敗: $tool"; done
}

install_cargo_tools() {
  command -v cargo &>/dev/null || { warn "cargo なし。スキップ"; return; }
  for tool in "${CARGO_TOOLS[@]}"; do cargo install "$tool" || warn "失敗: $tool"; done
}

main() {
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
    *) echo "使い方: $0 [all|apt|npm|pip|go|cargo]"; exit 1 ;;
  esac
  log "✓ 完了！"
}

main "$@"
