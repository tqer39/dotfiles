# RTK Healthcheck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** RTK (Rust Token Killer) が dotfiles 環境で正常動作しているかを 1 セッションで把握する。

**Architecture:** 3 段階の独立チェック（C: バイナリ → A: hook 設定 → B: 効果測定）を Bash で順次実行し、各項目を ✅/⚠️/❌ で報告。最後に総合判定を出す。スクリプト化はしない一回性タスク。

**Tech Stack:** bash, jq (settings.json パース), readlink, brew, rtk

---

## File Structure

このプランは検証のみで成果物（ファイル変更）を生まない。最後に検証結果を 1 つだけドキュメント化する。

- Create: `docs/superpowers/reports/2026-04-19-rtk-healthcheck-result.md` — 実行結果サマリ

---

### Task 1: C. バイナリ検証

**Files:** なし（コマンド実行のみ）

- [ ] **Step 1: バイナリパス確認**

Run: `command -v rtk`
Expected: `/opt/homebrew/bin/rtk`（macOS Homebrew 環境）

- [ ] **Step 2: バージョン確認**

Run: `rtk --version`
Expected: `rtk <semver>` 形式の文字列が返る（cost-optimization spec 時点では `0.37.1`）

- [ ] **Step 3: サブコマンド一覧確認**

Run: `rtk --help`
Expected: ヘルプテキストが返り、`init` サブコマンドが含まれる

- [ ] **Step 4: 結果を記録**

3 項目を ✅/⚠️/❌ で判定し、ローカルメモに残す（後段の Task 4 でレポートに統合）

---

### Task 2: A. hook セットアップ検証

**Files:** なし（読み取りのみ）

- [ ] **Step 1: settings.json の symlink 確認**

Run: `readlink ~/.claude/settings.json`
Expected: dotfiles リポジトリ内のパスを指す（例: `/Users/takeruooyama/.dotfiles/src/.claude/settings.personal.json`）。
- 出力なし → symlink ではない（要対処: `./scripts/dotfiles.sh install`）
- 出力あり → どのプロファイル (personal/work) が active か記録

- [ ] **Step 2: active settings.json に rtk hook が存在するか確認**

Run: `jq '.hooks.PreToolUse' ~/.claude/settings.json`
Expected: 配列が返り、その中に `rtk` を呼び出すエントリ（`command` フィールドに `rtk` を含む）がある。
- `null` → hook 未登録（要対処: `rtk init --global` 再実行 + dotfiles 反映）
- 配列はあるが rtk なし → 同上

- [ ] **Step 3: dotfiles ソース側にも反映されているか確認**

active プロファイルが personal なら:
Run: `jq '.hooks.PreToolUse' /Users/takeruooyama/.dotfiles/src/.claude/settings.personal.json`
work なら settings.work.json を見る。
Expected: Step 2 と同等の hook が記録されている（symlink なので本来一致するはずだが、念のため確認）

- [ ] **Step 4: 結果を記録**

3 項目を ✅/⚠️/❌ で判定し、メモに残す。

---

### Task 3: B. 効果測定（間接証拠）

**Files:** なし

- [ ] **Step 1: RTK のログ出力先を調査**

Run: `rtk --help 2>&1 | grep -iE 'log|debug|cache|verbose'`
Expected: ログ関連のオプションが見つかる、または何も無い（その場合は次ステップ）

Run: `ls -la ~/.cache/rtk/ ~/.local/share/rtk/ ~/Library/Caches/rtk/ 2>/dev/null`
Expected: 既存ログディレクトリがあれば中身を確認

- [ ] **Step 2: 直近セッションの圧縮痕跡を探す**

このセッション（または直前のセッション）の Bash ツール出力に RTK の介入マーカー
（例: `[rtk:`、`...truncated by rtk`、要約ヘッダー等）が混じっているか目視確認。
明確な痕跡がなければ「実証困難」と判定。

- [ ] **Step 3: 軽量な再現テストを試行**

Run: `RTK_DEBUG=1 rtk --help 2>&1 | head -20`（環境変数で詳細モードを有効化できるかの試行）
Expected: 何らかの diagnostic 出力 or 通常出力。情報がなければスキップ。

- [ ] **Step 4: 結果を記録**

✅（痕跡あり）/ ⚠️（実証困難だが設定は正しい）/ ❌（明確に動いていない証拠あり）で判定。

---

### Task 4: 結果レポート作成と総合判定

**Files:**
- Create: `docs/superpowers/reports/2026-04-19-rtk-healthcheck-result.md`

- [ ] **Step 1: ディレクトリ作成（必要なら）**

Run: `mkdir -p docs/superpowers/reports`

- [ ] **Step 2: レポート書き出し**

Task 1〜3 の結果を以下のテンプレートに埋めて `2026-04-19-rtk-healthcheck-result.md` に保存:

```markdown
# RTK ヘルスチェック実施結果 (2026-04-19)

## 環境
- OS: <`uname -srm` の出力>
- rtk version: <Task 1 Step 2 の出力>

## C. バイナリ検証
- バイナリパス: ✅/⚠️/❌ — <根拠>
- バージョン: ✅/⚠️/❌ — <根拠>
- サブコマンド: ✅/⚠️/❌ — <根拠>

## A. hook セットアップ
- symlink: ✅/⚠️/❌ — <根拠>
- active settings の hook: ✅/⚠️/❌ — <根拠>
- dotfiles ソース側: ✅/⚠️/❌ — <根拠>
- active プロファイル: <personal | work>

## B. 効果測定
- ログ出力先: ✅/⚠️/❌ — <根拠>
- 圧縮痕跡: ✅/⚠️/❌ — <根拠>
- 再現テスト: ✅/⚠️/❌ — <根拠>

## 総合判定
- <設定上は正常 | 動作実証済み | 要修正>

## 修正提案（要修正の場合のみ）
- <設計 spec の "想定される修正パス" 表に従って具体策>
```

- [ ] **Step 3: commit**

```bash
git add docs/superpowers/reports/2026-04-19-rtk-healthcheck-result.md
git commit -m "📝 RTK ヘルスチェック実施結果を記録"
```

- [ ] **Step 4: ユーザーに総合判定を報告**

判定結果と、要修正なら次のアクション提案を 1 メッセージで返す。

---

## Self-Review

- **Spec coverage:** 設計 spec の C/A/B 3 段階・出力形式・総合判定ルール・修正パスがすべて Task に対応している ✅
- **Placeholder scan:** 「TBD」「実装は後で」等なし。各 Step に具体コマンドあり ✅
- **Type consistency:** N/A（型を扱わない）
