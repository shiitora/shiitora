# dotfiles - 環境設定リポジトリ

複数端末間で開発環境を共有するためのdotfilesリポジトリです。

## 構成

```
.
├── shell/
│   ├── bashrc          # bash設定 (エイリアス、関数、プロンプトなど)
│   └── bash_profile    # ログインシェル設定
├── git/
│   ├── gitconfig       # Git設定 (ユーザー情報以外)
│   └── gitignore_global # グローバルgitignore
├── vim/
│   └── vimrc           # Vim設定
├── tmux/
│   └── tmux.conf       # Tmux設定
├── claude/
│   └── settings.json   # Claude Code設定
└── scripts/
    ├── install.sh      # シンボリックリンク作成スクリプト
    └── packages.sh     # パッケージインストールスクリプト
```

## 新しい端末へのセットアップ手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/shiitora/shiitora.git ~/dotfiles
cd ~/dotfiles

# 2. dotfilesをインストール (シンボリックリンク作成)
./scripts/install.sh

# 3. シェル設定を反映
source ~/.bashrc

# 4. 個人情報を設定
vim ~/.gitconfig.local
# [user]
#   name = Your Name
#   email = your@email.com

# 5. (任意) この端末固有の設定
vim ~/.bashrc.local

# 6. (任意) パッケージのインストール
./scripts/packages.sh
```

## 端末固有の設定

以下のファイルはGit管理外で、端末ごとに異なる設定を書きます：

| ファイル | 用途 |
|---|---|
| `~/.bashrc.local` | この端末固有のエイリアス・PATH設定など |
| `~/.gitconfig.local` | 名前・メールアドレス |
| `~/.vimrc.local` | この端末固有のVim設定 |

## 設定のカスタマイズ

他の端末で使っている設定があれば、このリポジトリの各ファイルに追加してください。

- シェルのエイリアスや関数: `shell/bashrc`
- Git設定: `git/gitconfig`
- Vimの設定: `vim/vimrc`
- Tmuxの設定: `tmux/tmux.conf`
- Claude Codeの権限設定: `claude/settings.json`
