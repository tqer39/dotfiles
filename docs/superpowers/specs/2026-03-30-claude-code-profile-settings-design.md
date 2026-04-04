# Claude Code ユーザースコープ設定のプロファイル管理

## Context

Claude Code のユーザースコープ設定（`~/.claude/settings.json`, `~/.claude/plugins/`）は現在 dotfiles で管理されていない。個人用と会社用で異なる設定（permissions, hooks, plugins 等）を使い分けたいが、手動管理は煩雑でミスが起きやすい。

このリポジトリには既に `DOTFILES_MODE`（personal/work）による設定切替機構があり（gitconfig, mise config で利用中）、Claude Code 設定もこのパターンに統合する。

## Approach

**ファイル分離 + symlink 切替**（既存パターン踏襲）

個人用・会社用を別ファイルで `src/.claude/` に配置し、`DOTFILES_MODE` に応じて symlink 先を切り替える。gitconfig, mise config と同一のパターン。

## File Structure

```text
src/.claude/
  settings.personal.json
  settings.work.json
  plugins/
    installed_plugins.personal.json
    installed_plugins.work.json
    config.personal.json
    config.work.json
```

## Symlink Mapping

`DOTFILES_MODE` に応じて以下の symlink を作成:

| DOTFILES_MODE | Source | Target |
| --- | --- | --- |
| personal | `src/.claude/settings.personal.json` | `~/.claude/settings.json` |
| work | `src/.claude/settings.work.json` | `~/.claude/settings.json` |
| personal | `src/.claude/plugins/installed_plugins.personal.json` | `~/.claude/plugins/installed_plugins.json` |
| work | `src/.claude/plugins/installed_plugins.work.json` | `~/.claude/plugins/installed_plugins.json` |
| personal | `src/.claude/plugins/config.personal.json` | `~/.claude/plugins/config.json` |
| work | `src/.claude/plugins/config.work.json` | `~/.claude/plugins/config.json` |

## Implementation

### 1. 設定ファイルの作成

`src/.claude/` 配下に6つの設定ファイルを作成。現在の `~/.claude/settings.json` と `~/.claude/plugins/` の内容をベースに、個人用・会社用に分離。

### 2. `scripts/dotfiles.sh` への統合

`install_dotfiles` 関数内に `install_claude_settings` 関数を追加:

```bash
install_claude_settings() {
  local mode="${DOTFILES_MODE:-personal}"
  local src_dir="${DOTFILES_DIR}/src/.claude"

  create_symlink "${src_dir}/settings.${mode}.json" \
                 "${HOME}/.claude/settings.json"
  create_symlink "${src_dir}/plugins/installed_plugins.${mode}.json" \
                 "${HOME}/.claude/plugins/installed_plugins.json"
  create_symlink "${src_dir}/plugins/config.${mode}.json" \
                 "${HOME}/.claude/plugins/config.json"
}
```

### 3. サブコマンド対応

- **install**: `install_claude_settings` を呼び出し
- **uninstall**: 3つの symlink を `remove_symlink` で削除
- **doctor**: symlink が正しいモードのファイルを指しているか検証
- **status**: 現在の Claude Code 設定の symlink 状態を表示

### 4. 除外対象

- `~/.claude.json` — スコープ外（ユーザーの要件）
- `~/.claude/settings.local.json` — セッション固有の権限設定、dotfiles 管理に不適
- `~/.claude/sessions/`, `~/.claude/plans/`, `~/.claude/tasks/` — 一時データ

## Modified Files

- `src/.claude/settings.personal.json` (新規)
- `src/.claude/settings.work.json` (新規)
- `src/.claude/plugins/installed_plugins.personal.json` (新規)
- `src/.claude/plugins/installed_plugins.work.json` (新規)
- `src/.claude/plugins/config.personal.json` (新規)
- `src/.claude/plugins/config.work.json` (新規)
- `scripts/dotfiles.sh` (既存: install/uninstall/doctor/status に Claude Code 対応追加)

## Verification

1. `./scripts/dotfiles.sh install` を実行し、`~/.claude/settings.json` が正しいファイルへの symlink になっていることを確認
2. `DOTFILES_MODE=work ./scripts/dotfiles.sh install` で会社用に切り替わることを確認
3. `./scripts/dotfiles.sh status` で Claude Code 設定の状態が表示されることを確認
4. `./scripts/dotfiles.sh doctor` でヘルスチェックが通ることを確認
5. `./scripts/dotfiles.sh uninstall` で symlink が削除されることを確認
6. 冪等性: 2回連続で install を実行しても問題ないことを確認
