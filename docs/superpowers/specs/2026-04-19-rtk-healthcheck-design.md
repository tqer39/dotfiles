# RTK ヘルスチェック設計

## 概要

dotfiles 環境にインストール済みの RTK (Rust Token Killer, Homebrew パッケージ `rtk`) が
正常動作しているかを 1 セッション内で把握するための、一回性のヘルスチェック手順を定義する。

スクリプト化はせず、手動ステップで対話的に検証する。問題が見つかった場合は修正提案で締める。
将来的に頻度が増えた場合のみ `scripts/diagnostics/rtk-healthcheck.sh` への昇格を検討する。

## 背景

- RTK は `2026-04-14-claude-code-cost-optimization-design.md` で導入された LLM トークン削減用 CLI プロキシ
- セットアップは `rtk init --global` 由来の PreToolUse hook を `~/.claude/settings.json` に登録する形
- インストール直後やプロファイル切替後に「実際に効いているか」を確認したくなる

## 検証範囲

3 段階の独立チェック。下位レイヤから順に実行する。

| # | 対象 | 質問 |
|---|---|---|
| C | RTK バイナリ | 実行可能か / version は何か / サブコマンドが応答するか |
| A | hook セットアップ | settings.json に PreToolUse hook が登録されているか / dotfiles ソース側にも反映されているか |
| B | 効果測定 | RTK が実際に介入しているか（ログ・stderr 痕跡など間接証拠） |

実行順は **C → A → B**。C が壊れていたら A/B を見る意味がない。

## 検証手順

### C. バイナリ検証

- `command -v rtk` → `/opt/homebrew/bin/rtk` が返る
- `rtk --version` → バージョン文字列が返る（現状想定: `rtk 0.37.1`）
- `rtk --help` → サブコマンド一覧（`init` 等）が応答する

### A. hook セットアップ検証

- `readlink ~/.claude/settings.json` → dotfiles 内のパスを指す（symlink 化されている）
- `~/.claude/settings.json` の `hooks.PreToolUse` 配下に `rtk` を呼ぶエントリが存在
- dotfiles ソース (`src/.claude/settings.personal.json` または `settings.work.json`) にも
  同等の hook が記録されている
- 現在 active なプロファイル (personal/work) を判定し、両者の差異を確認

### B. 効果測定（間接証拠）

- RTK のログ出力先を調査（`rtk --help`、`--debug` 系オプション、`~/.cache/rtk/` などの有無）
- 直近セッションで Bash ツール出力に圧縮の痕跡（要約マーカー、`[rtk: ...]` など）があるか
- ログが取得できない場合は「設定上は正常だが実証は困難」と明記し、軽量な再現テストを提案

## 出力形式

各項目を `✅` / `⚠️` / `❌` + 1〜2 行の根拠で報告し、最後に総合判定を出す。

## 総合判定ルール

- C がすべて ✅ かつ A の hook 登録 ✅ → **設定上は正常**
- 加えて B で痕跡確認 ✅ → **動作実証済み**
- いずれかが ❌ → **要修正**。修正提案を併記する

## スコープ外

- ヘルスチェックのスクリプト化（必要が出てから別 spec で扱う）
- RTK 自体の設定値チューニング
- `dotfiles.sh doctor` への統合
- トークン削減量の定量計測（ログが残っていないため、本 spec ではやらない）

## 想定される修正パス

| 症状 | 想定原因 | 対処 |
|---|---|---|
| `rtk` not found | Brewfile 未適用 | `brew bundle --file=config/packages/Brewfile` |
| settings.json に hook なし | `rtk init --global` 未実行 / 反映漏れ | cost-optimization spec の手順 §3 を再実行 |
| symlink が壊れている | `dotfiles.sh install` 未実行 | `./scripts/dotfiles.sh install` |
| hook はあるが効いてない | RTK の hook フォーマット変更等 | `rtk --version` を最新と比較し、`rtk init --global` 再生成を検討 |
