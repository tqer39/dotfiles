# Zellij + Claude Code ワークフロー

Ghostty + Zellij + Claude Code を組み合わせた開発フロー。macOS 環境（Karabiner あり）を前提とする。

## 想定環境

| レイヤー | ツール | 役割 |
| --- | --- | --- |
| ターミナルエミュレータ | Ghostty | 1 ウィンドウ起動、タブ = リポジトリ |
| ターミナルマルチプレクサ | Zellij | タブ内でペイン/タブ分割 + セッション永続化 |
| AI ペアプログラミング | Claude Code | Zellij ペインで常駐 |
| キーボードリマップ | Karabiner | OS レベルのキーバインド |

## 階層イメージ

```text
Ghostty (1 window)
├── Tab 1: ~/.dotfiles              ← Ghostty タブ = リポジトリ
│   └── Zellij session: dotfiles
│       ├── Zellij tab 1: main
│       │   └── pane: shell         ← claude / 通常シェル共用
│       └── Zellij tab 2: test      ← テスト実行用
│
├── Tab 2: ~/workspace/project-a    ← 別リポジトリ
│   └── Zellij session: project-a
│       └── ...
│
└── Tab 3: ~/workspace/project-b
    └── Zellij session: project-b
        └── ...
```

**ポイント:**

- Ghostty タブ ≒ リポジトリ（作業ディレクトリで分離）
- Zellij セッション名 = リポジトリ名（再接続が楽）
- Zellij タブ = 作業コンテキスト（main / test / docs など）
- Claude Code はシェルペイン内で `claude` コマンドとして常駐させ、デタッチで生存し続ける

## セットアップ

### 1. 初回インストール

```bash
cd ~/.dotfiles
./scripts/dotfiles.sh install   # symlink 作成
source ~/.zshrc                 # zj 関数を読み込み
```

インストール後のシンボリックリンク:

- `~/.config/zellij/config.kdl` → `src/.config/zellij/config.kdl`
- `~/.config/zellij/layouts/default.kdl` → `src/.config/zellij/layouts/default.kdl`

### 2. 動作確認

```bash
zellij --version        # v0.44.x
zellij list-sessions    # 現在のセッション一覧（未起動時は空）
```

## 日々のワークフロー

### A. 新規リポジトリで作業を開始する

1. **Ghostty で新規タブを開く**: `cmd + t`
2. **リポジトリへ移動**: `cd ~/workspace/foo`
3. **Zellij セッション起動（default レイアウト）**

   ```bash
   zj dotfiles    # dotfiles という名前のセッション
   zj foo         # foo という名前のセッション
   ```

   - 初回: 指定名のセッションを新規作成、`default` レイアウトでシェルペインが起動
   - 2回目以降: 既存セッションに attach
   - zellij セッションの中から `zj <別名>` を実行すると `switch-session` で同じターミナル上で切り替わる（入れ子にならない）

4. **シェルペインで `claude` を起動**してプロンプトを入力

### B. 作業を中断する（デタッチ）

- `Ctrl+o` → `d`（session モード → detach）
- または `Ctrl+o` → `w` でセッションマネージャーを開いて操作
- ターミナルを閉じても OK（`on_force_close "detach"` によりセッション維持）

### C. 作業を再開する

```bash
# 同じリポジトリのタブで
zj dotfiles
```

セッションが生きていればペイン構成が復元される（Claude Code の会話状態はシェルペイン内で `claude --continue` で復元）。

### D. Claude Code の会話履歴を復元する

Zellij セッションを復元しても Claude Code の TUI 状態までは戻らないため、会話の継続は Claude Code 側の機能を使う:

```bash
# claude ペイン内で
claude --continue       # 直近の会話を継続
claude --resume         # 会話一覧から選択
```

シェルペインの起動コマンドとして固定したい場合、`layouts/default.kdl` の `shell` ペイン定義へ `command "claude" args "--continue"` を追加できる。ただし default レイアウトである以上、あらゆる新規タブにも同じ挙動が波及する点は要注意。

### E. 複数の作業コンテキストを切り替える

Zellij タブを追加で作る:

- `Ctrl+t` → `n`: 新規タブ
- `Ctrl+t` → `1`/`2`/`3`: タブ切替
- `Alt+h` / `Alt+l`: タブを左右に移動

例:

- Tab 1 (`main`): Claude Code + shell
- Tab 2 (`test`): `just test --watch` 常駐
- Tab 3 (`git`): `lazygit` 常駐

## キーバインドチートシート

### Ghostty（OS/ターミナル層）

| キー | 動作 |
| --- | --- |
| `cmd + t` | 新規タブ |
| `cmd + w` | タブを閉じる |
| `cmd + shift + [` / `]` | タブ切替 |
| `cmd + shift + click` | URL を開く（zellij バイパス） |
| `cmd + r` | fzf 履歴検索（`ctrl+r` にリマップ） |

### Zellij モード切替（プレフィックス）

`Ctrl+g` でロック/解除を切り替え可能。ロックモードではすべてのキーがアプリに直通。

| キー | モード | 用途 |
| --- | --- | --- |
| `Ctrl+p` | Pane | ペイン操作 |
| `Ctrl+t` | Tab | タブ操作 |
| `Ctrl+n` | Resize | ペインリサイズ |
| `Ctrl+s` | Scroll | スクロール/検索 |
| `Ctrl+o` | Session | デタッチ/セッションマネージャー |
| `Ctrl+h` | Move | ペイン移動 |
| `Ctrl+b` | tmux | tmux 互換モード |
| `Ctrl+g` | Lock | キー透過モード |
| `Ctrl+q` | — | Zellij 終了 |

### Pane モード（`Ctrl+p` 後）

| キー | 動作 |
| --- | --- |
| `r` | 右に分割 |
| `d` | 下に分割 |
| `s` | スタック分割 |
| `h` / `j` / `k` / `l` | フォーカス移動 |
| `f` | フルスクリーン |
| `w` | フローティング切替 |
| `e` | 埋込/フロート切替 |
| `c` | ペイン名変更 |
| `x` | ペインを閉じる |
| `z` | ペイン枠の表示切替 |

### Tab モード（`Ctrl+t` 後）

| キー | 動作 |
| --- | --- |
| `n` | 新規タブ |
| `1` - `9` | タブ番号指定 |
| `h` / `l` | 前後タブ |
| `r` | タブ名変更 |
| `x` | タブを閉じる |
| `[` / `]` | ペインを隣接タブへ |

### Session モード（`Ctrl+o` 後）

| キー | 動作 |
| --- | --- |
| `d` | デタッチ |
| `w` | セッションマネージャー |
| `c` | 設定プラグイン |
| `l` | レイアウトマネージャー |
| `p` | プラグインマネージャー |

### 常時有効なショートカット（Alt 系）

| キー | 動作 |
| --- | --- |
| `Alt+h` / `Alt+l` | ペイン or タブ左右移動 |
| `Alt+j` / `Alt+k` | ペイン上下移動 |
| `Alt+n` | 新規ペイン |
| `Alt+f` | フローティング切替 |
| `Alt+[` / `Alt+]` | スワップレイアウト |
| `Alt++` / `Alt+-` | リサイズ |

### Claude Code（TUI 内）

| キー | 動作 |
| --- | --- |
| `esc` 2回 | 入力キャンセル |
| `shift+tab` | プランモード切替 |
| `/` | スラッシュコマンド |
| `ctrl+c` | 処理中断 |

## よくある使い方レシピ

### R1. 朝の立ち上げ（1分で作業再開）

```bash
# Ghostty 起動 → タブで cd
cd ~/.dotfiles
zj dotfiles               # 昨日の状態に復元
# Claude ペインで
claude --continue         # 昨日の会話継続
```

### R2. 一時的に作業を退避する

`Ctrl+o` → `d` でデタッチ。別のリポジトリに移動して別のセッションで作業し、終わったら `zj dotfiles` で戻る。

### R3. 長時間タスクをバックグラウンドで走らせる

1. `Ctrl+t` → `n` で新規 Zellij タブ
2. `just test --watch` 起動
3. `Ctrl+o` → `d` でデタッチ
4. ターミナル閉じても OK
5. 翌日 `zj dotfiles` で戻ると結果が見られる

### R4. セッションの掃除

```bash
zellij list-sessions             # 一覧
zellij delete-session <name>     # 個別削除
zellij delete-all-sessions       # 全削除
```

## トラブルシュート

### Claude Code が起動しない

シェルペインで `claude` を打っても not found になる場合、mise / PATH の初期化が `zj` 起動より先に完了しているか確認。
→ `.zshrc` で mise 初期化後に `zj` を呼ぶこと。

### セッションが復元されない

- `zellij list-sessions` で EXITED 状態になっているか確認
- `session_serialization true` が有効か `config.kdl` を確認
- キャッシュ: `~/Library/Caches/org.Zellij-Contributors.Zellij/` or `~/.cache/zellij/`

### URL をマウスクリックで開けない／テキスト選択できない

zellij がマウスイベントを捕捉しているため、ターミナル出力中の URL を普通にクリックしても Ghostty まで届かない。

**対処**: `cmd + shift + クリック` で URL を開く。テキスト選択したい場合は `cmd + shift + ドラッグ`。`cmd` か `shift` 単体ではバイパスできず、同時押しが必要。

**恒久対応（オプション）**: `src/.config/zellij/config.kdl` に `mouse_mode false` を追加すれば、zellij のマウスキャプチャを無効化してマウス操作を常に Ghostty 側へ渡せる。ただし zellij のマウス操作（ペインクリック切替、タブクリック、ドラッグリサイズ等）は使えなくなるトレードオフを伴う。通常は上記ショートカットで十分。

### Ghostty のキーバインドと衝突した

Ghostty の `super+` 系と Zellij の `Ctrl+`/`Alt+` 系はモディファイア空間が独立しているため衝突しない設計。もし衝突する場合は `config.kdl` のキーバインドを調整。

### Karabiner が Zellij のキーを奪う

Karabiner の現在の設定は Ghostty アプリに対するリマップが中心（`^com\.mitchellh\.ghostty`）。
Zellij 内部のキー入力は、Ghostty へ渡す前に Karabiner が介入するので注意:

- `cmd+r` → `ctrl+r`（履歴検索）— zellij の挙動には影響なし
- `ctrl+insert` → コピー、`shift+insert` → 貼付
- `cmd+l` → クリア

これらは Zellij のキーバインドとぶつからないので問題なし。もし競合したら Karabiner 側で Ghostty アプリ条件を外す。

## 関連ファイル

- `src/.config/zellij/config.kdl` — Zellij 本体設定（`Alt+g` で lazygit floating など）
- `src/.config/zellij/layouts/default.kdl` — default レイアウト（shell ペイン）
- `src/.config/ghostty/config` — Ghostty 設定
- `src/.config/karabiner/karabiner.json` — Karabiner 設定
- `src/.shell_common` — `zj` 関数定義
- `config/platform-files.conf` — symlink 定義
