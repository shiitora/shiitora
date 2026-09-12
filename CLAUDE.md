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

## 他の端末のスレッドに入る (Remote Control)

`claude/settings.json` で `remoteControlAtStartup: true` を設定しているため、
`./scripts/install.sh` を実行した端末では、対話セッション起動時に自動で
Remote Control に接続されます。これにより [claude.ai/code](https://claude.ai/code)
やスマホアプリ (Code タブ) のセッション一覧からその端末のスレッドに入れます。

| やりたいこと | 操作 |
|---|---|
| 他端末のスレッドに入る | claude.ai/code かスマホアプリのセッション一覧から選ぶ (PCアイコン＋緑のドットが接続中) |
| URLで直接入る | `https://claude.ai/code/<session_id>` |
| 接続中のスレッドのURL/QRを表示 | セッション内で `/remote-control` (略: `/rc`) |
| 未接続のスレッドを繋ぐ | そのターミナルで `/remote-control` を実行 (会話履歴を引き継ぐ) |
| 止めたサーバーを復活させる | 同じディレクトリで `claude remote-control --continue` (停止後4時間以内) |
| 複数スレッドを遠隔操作する | `claude remote-control` (サーバーモード) |

注意点：

- この設定は**ユーザー設定** (`~/.claude/settings.json`) として効きます。
  プロジェクト側の `.claude/settings.json` に `true` を書いても無視される仕様です
  (リポジトリをクローンした他人の端末を勝手に接続させないため)。逆に `false` は効きます。
- `DISABLE_TELEMETRY` / `DO_NOT_TRACK` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` /
  `DISABLE_GROWTHBOOK` や `ANTHROPIC_BASE_URL` を設定している端末では Remote Control が使えません。
  `~/.bashrc.local` でこれらを設定していないか確認してください。
- 自動接続は自分の claude.ai アカウントでサインインするため、他人にアクセス権は渡りません。
- 接続中はセッションの会話内容が Anthropic のサーバーに保存されます
  (端末間で同期し、切断後に復帰するため)。コードの実行とファイルアクセスは端末側のままです。
- 無効化したい端末では `~/.claude/settings.json` のシンボリックリンクを外すのではなく、
  そのプロジェクトの `.claude/settings.local.json` に `{"remoteControlAtStartup": false}` を書いてください。
