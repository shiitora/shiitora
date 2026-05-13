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
    ├── install.sh        # シンボリックリンク作成スクリプト
    ├── packages.sh       # パッケージインストールスクリプト
    ├── gdrive-sync.sh    # Google Drive ↔ ローカル ミラーリング
    ├── capture.sh        # 現在の環境をGoogle Driveに保存
    ├── restore.sh        # Google Driveから環境を復元
    └── setup-new-pc.ps1  # Windows新規セットアップ (PowerShell)
```

## 新しいLinux端末へのセットアップ手順

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

# 5. Google Driveから環境を復元 (スキル + パッケージ)
./scripts/gdrive-sync.sh install  # rcloneインストール
rclone config                     # gdrive認証
./scripts/restore.sh              # 復元
```

## 新しいWindows端末へのセットアップ手順

```powershell
# PowerShellで実行
.\scripts\setup-new-pc.ps1
```

## 端末固有の設定

以下のファイルはGit管理外で、端末ごとに異なる設定を書きます：

| ファイル | 用途 |
|---|---|
| `~/.bashrc.local` | この端末固有のエイリアス・PATH設定など |
| `~/.gitconfig.local` | 名前・メールアドレス |
| `~/.vimrc.local` | この端末固有のVim設定 |

## Google Drive 経由の同期 (rclone)

Windows の `C:\G` (Google Drive) に置いた設定をこのLinuxに持ってくることができます。

### 初回セットアップ (このLinux側)

```bash
./scripts/gdrive-sync.sh install
rclone config
# → n (新規) → 名前: gdrive → 種類: drive → ブラウザで認証
```

### ソース端末 (Windows等) でキャプチャ

```bash
./scripts/capture.sh
```

### このLinuxに復元

```bash
./scripts/restore.sh              # 全部復元
./scripts/restore.sh claude       # Claude Code スキル・設定のみ
./scripts/restore.sh npm          # npm のみ
./scripts/restore.sh pip          # pip のみ
./scripts/restore.sh apt          # apt のみ
```

### 同期対象

| Google Drive | ローカル | 内容 |
|---|---|---|
| `G:\.claude\` | `~/.claude/` | Claude Code設定・スキル (slash commands) |
| `G:\packages\npm-globals.txt` | (インストールに使用) | npm グローバルパッケージ一覧 |
| `G:\packages\pip-requirements.txt` | (インストールに使用) | pip パッケージ一覧 |
| `G:\packages\apt-packages.txt` | (インストールに使用) | apt パッケージ一覧 |

### スクリプト一覧

| スクリプト | 実行場所 | 用途 |
|---|---|---|
| `scripts/capture.sh` | ソース端末 | 現在の環境をGoogle Driveに保存 |
| `scripts/restore.sh` | このLinux | Google DriveからLinuxに復元 |
| `scripts/gdrive-sync.sh` | どちらでも | Google Drive ↔ ローカル ミラーリング |
| `scripts/setup-new-pc.ps1` | Windows | 新規Windows PCのセットアップ |

## 設定のカスタマイズ

- シェルのエイリアスや関数: `shell/bashrc`
- Git設定: `git/gitconfig`
- Vimの設定: `vim/vimrc`
- Tmuxの設定: `tmux/tmux.conf`
- Claude Codeの権限設定: `claude/settings.json`
