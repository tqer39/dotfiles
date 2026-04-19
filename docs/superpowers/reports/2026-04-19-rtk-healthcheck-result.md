# RTK ヘルスチェック実施結果 (2026-04-19)

## 環境

- OS: Darwin 25.3.0 arm64 (macOS)
- rtk version: 0.37.1
- active プロファイル: personal

## C. バイナリ検証

- バイナリパス: ✅ — `/opt/homebrew/bin/rtk`
- バージョン: ✅ — `rtk 0.37.1`
- サブコマンド: ✅ — `init` を含む全サブコマンド応答 (`gain`, `cc-economics` など効果測定系も利用可)

## A. hook セットアップ

- symlink: ✅ — `~/.claude/settings.json` → `~/.dotfiles/src/.claude/settings.personal.json`
- active settings の hook: ❌ — `hooks.PreToolUse` には `require-worktree.sh` のみ。**rtk hook なし**
- dotfiles ソース側: ❌ — `settings.personal.json` / `settings.work.json` どちらにも rtk hook なし。
  リポジトリ全体で `rtk` への参照は `Brewfile` と spec のみで、実 hook 設定は存在しない

## B. 効果測定

- ログ/データ出力先: ✅ — `~/Library/Application Support/rtk/` に `history.db` (SQLite) と
  `.hook_warn_last` (空ファイル、Apr 19 09:00 更新) を確認
- 圧縮痕跡: ❌ — `rtk gain` → "No tracking data yet"。`rtk cc-economics` →
  **RTK commands: 0 / Tokens saved: 0** (決定的証拠)
- 再現テスト: ✅ — `cc-economics` が累計 $558.29 の Claude Code 利用に対し
  RTK 経由のコマンドが 0 件であることを明示

## 総合判定

❌ **要修正**

RTK バイナリ自体は健全にインストール・動作可能だが、Claude Code から RTK を呼び出す
PreToolUse hook が dotfiles 内・active settings 双方に未登録。すなわち
`2026-04-14-claude-code-cost-optimization-design.md` §3 の「RTK PreToolUse hook 設定手順」
が実施されていない状態。結果としてトークン削減効果はゼロ。

## 修正提案

cost-optimization spec §3 の手順を実施する:

1. settings.json の symlink を一時的に外す
   - `unlink ~/.claude/settings.json`
2. `rtk init --global` を実行して hook 設定を生成
3. 生成された `~/.claude/settings.json` の `hooks.PreToolUse` 配下から rtk エントリを抽出
4. 抽出した rtk エントリを `src/.claude/settings.personal.json` の `hooks.PreToolUse`
   に既存の `require-worktree.sh` エントリと併存する形でマージ
   - 同様に `settings.work.json` にも反映するか検討
5. symlink を再作成
   - `./scripts/dotfiles.sh install`
6. 動作確認: 任意のセッションでツール呼び出し後 `rtk cc-economics` を再実行し、
   `RTK commands` が増えることを確認

## 補足

- `.hook_warn_last` が今日 (Apr 19 09:00) のタイムスタンプで存在する点は気になる。
  RTK 側で hook 未設定を検知したマーカーである可能性があるが、現時点では未調査。
  修正後に再発したら詳細調査する
- `cc-economics` が累計 $558.29 のコスト分析を即座に出せるのは、修正後の効果検証にも
  そのまま使える
