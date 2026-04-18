# Claude Code コスト最適化 設計

## Context

Claude Code の API トークン消費を削減するため、ユーザー設定とツールチェーンを最適化する。
コミュニティで共有されている最適化設定値（env 変数 4 種、effortLevel）と、コマンド出力を圧縮する
RTK (Rust Token Killer) を導入する。

**目標**: コスト削減を最優先（速度・品質より優先）
**適用範囲**: personal / work モードの両方。

## アーキテクチャ

dotfiles 既存の symlink ベース設定管理に従う。

- `src/.claude/settings.{personal,work}.json` を編集（`~/.claude/settings.json` の symlink 元）
- `config/packages/Brewfile` に RTK パッケージ追加
- RTK の PreToolUse hook 設定は `rtk init --global` で生成させ、内容を dotfiles ソースに手動反映

## 変更内容

### 1. env 変数追加（settings.personal.json / settings.work.json 両方）

既存の `"env"` ブロックに 4 変数追加：

| 変数 | 値 | 効果 |
| --- | --- | --- |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | `"1"` | 1M トークンコンテキスト無効化（高単価回避） |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | `"1"` | 拡張思考を無効化（思考トークン削減） |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | `"1"` | 自動メモリ機能無効化（コンテキスト肥大化防止） |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `"sonnet"` | Sub agent を Sonnet に固定（Opus 単価回避） |

### 2. effortLevel 追加（settings.personal.json / settings.work.json 両方）

トップレベルに追加：

```json
"effortLevel": "high"
```

### 3. RTK 導入

**Brewfile 追加**（`config/packages/Brewfile`）:

`# Development tools` セクション末尾（`brew "prek"` の次行）に追加：

```ruby
brew "rtk"          # CLI proxy for LLM token optimization
```

**RTK PreToolUse hook 設定手順**（一度きりの手動オペレーション）:

1. `brew bundle --file=config/packages/Brewfile` で RTK インストール
2. `~/.claude/settings.json` の symlink を一時的に外す（`./scripts/dotfiles.sh uninstall` または手動 unlink）
3. `rtk init --global` を実行して hook 設定を生成
4. 生成された `~/.claude/settings.json` の hook ブロックから PreToolUse 部分を抽出
5. `src/.claude/settings.personal.json` と `src/.claude/settings.work.json` の `hooks` ブロックに手動コピー（既存の `Stop` hook と並べて配置）
6. `./scripts/dotfiles.sh install` で再 symlink

## 変更ファイル一覧

- `src/.claude/settings.personal.json` — env 4 変数 + effortLevel + (後で) PreToolUse hook
- `src/.claude/settings.work.json` — 同上
- `config/packages/Brewfile` — `brew "rtk"` 追加

`.claude/settings.json`（プロジェクトレベル、当 dotfiles リポジトリ用）は変更しない。
RTK と env 最適化はユーザーレベルの関心事のため。

## 検証手順

### Phase 1: 設定ファイル変更後

```bash
# JSON 構文チェック
jq . src/.claude/settings.personal.json
jq . src/.claude/settings.work.json

# Lint
just lint

# 再 symlink して反映
./scripts/dotfiles.sh install
./scripts/dotfiles.sh status
```

### Phase 2: env 変数反映確認

新しい Claude Code セッションを起動し、以下が反映されていることを確認：

- 1M context モードが選択肢に出ない
- Subagent が Sonnet で動作（Opus アイコンが出ない）
- 自動メモリ保存が走らない

### Phase 3: RTK 動作確認

```bash
brew install rtk      # まだなら
rtk --version
rtk gain              # トークン節約量レポート
```

hook 反映後、Bash ツール経由のコマンド（例: `git status`）が透過的に `rtk` ラップされて
出力サイズが小さくなることを確認。

## トレードオフと注意点

- **1M context 無効化**: 大規模リポジトリ全体読み込みは標準 200K まで縮小。本リポジトリ規模では問題なし
- **Adaptive thinking 無効化**: 複雑な推論タスクで品質低下の可能性。コスト優先方針で許容
- **Subagent=Sonnet**: Explore / Plan agent が Sonnet になる。Opus 比で速度向上、品質はやや低下
- **RTK hook**: `rtk init --global` は symlink 元を直接編集できないため一時 unlink が必要。手順を docs に残す価値あり
- **Stop hook の `afplay`**: 既存の macOS 専用 hook。本変更とは無関係だが Linux で警告が出る可能性は継続
