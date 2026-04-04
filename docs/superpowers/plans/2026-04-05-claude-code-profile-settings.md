# Claude Code Profile Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code のユーザースコープ設定（settings.json と plugins/）を個人用・会社用で分けて、dotfiles の symlink 機構で管理する。

**Architecture:** 既存の `DOTFILES_MODE`（personal/work）パターンに従い、`src/.claude/` 配下に環境別設定ファイルを配置する。`scripts/dotfiles.sh` に Claude Code 専用の処理を追加し、`DOTFILES_MODE` に応じて symlink 先を切り替える。

**Tech Stack:** Bash と symlink。既存の dotfiles フレームワーク（`create_symlink` / `remove_symlink` / `is_symlink_valid`）を利用する。

**Spec:** `docs/superpowers/specs/2026-03-30-claude-code-profile-settings-design.md`

---

## File Structure

| File | Action | Responsibility |
| ------ | -------- | --------------- |
| `src/.claude/settings.personal.json` | Create | 個人用 Claude Code settings |
| `src/.claude/settings.work.json` | Create | 会社用 Claude Code settings |
| `src/.claude/plugins/installed_plugins.personal.json` | Create | 個人用プラグインリスト |
| `src/.claude/plugins/installed_plugins.work.json` | Create | 会社用プラグインリスト |
| `src/.claude/plugins/config.personal.json` | Create | 個人用プラグイン設定 |
| `src/.claude/plugins/config.work.json` | Create | 会社用プラグイン設定 |
| `scripts/dotfiles.sh` | Modify | install/uninstall/status に Claude Code 処理追加 |
| `scripts/lib/doctor.sh` | Modify | Claude Code symlink ヘルスチェック追加 |

---

### Task 1: 個人用設定ファイルの作成

**Files:**

- Create: `src/.claude/settings.personal.json`
- Create: `src/.claude/plugins/installed_plugins.personal.json`
- Create: `src/.claude/plugins/config.personal.json`

現在の `~/.claude/settings.json` と `~/.claude/plugins/` の内容をそのまま個人用設定として配置する。

- [ ] **Step 1: settings.personal.json を作成**

`src/.claude/settings.personal.json` を以下の内容で作成:

```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  },
  "includeCoAuthoredBy": false,
  "permissions": {
    "allow": [
      "WebFetch(domain:raw.githubusercontent.com)",
      "Bash(pnpm install:*)",
      "Bash(mise trust:*)",
      "Bash(mise install:*)",
      "Bash(uv sync:*)",
      "Bash(uv run pytest:*)",
      "Bash(pnpm test:*)",
      "Bash(pnpm biome check:*)",
      "Bash(uv run ruff:*)",
      "Bash(echo:*)",
      "Bash(git add:*)",
      "Bash(mise exec:*)",
      "Bash(git ls-tree:*)",
      "Bash(git log:*)",
      "Bash(gh auth status:*)",
      "Bash(gh label:*)",
      "Bash(gh label create:*)",
      "Bash(gh api:*)",
      "Bash(gh issue create:*)",
      "Bash(gh issue list:*)",
      "Bash(lefthook install:*)",
      "Bash(pnpm lefthook:*)",
      "Bash(just lint:*)",
      "Bash(just test)",
      "Bash(gh pr list:*)",
      "Bash(gh pr view:*)",
      "Bash(gh pr edit:*)",
      "Bash(git push:*)",
      "Bash(npx vitest run)",
      "Bash(git commit:*)",
      "Bash(gh issue close:*)",
      "Bash(gh run view:*)",
      "WebFetch(domain:github.com)",
      "Bash(git check-ignore:*)",
      "Bash(cat:*)",
      "Bash(git fetch:*)",
      "Bash(pnpm exec cspell:*)",
      "WebSearch",
      "Bash(pre-commit run:*)",
      "Bash(gh issue view:*)",
      "Bash(gh pr create:*)",
      "Bash(git checkout:*)",
      "Bash(gh run list:*)",
      "Bash(pnpm prettier:*)",
      "Bash(gh pr merge:*)",
      "Bash(git pull:*)",
      "Bash(git reset:*)",
      "Bash(gh pr checks:*)",
      "Bash(git branch:*)",
      "Bash(gh issue edit:*)",
      "Bash(just worktree-list:*)",
      "Bash(just worktree-create:*)",
      "Bash(just worktree-remove-with-branch:*)",
      "Bash(git rebase:*)",
      "Bash(find:*)",
      "Bash(git stash push:*)",
      "Bash(git stash:*)",
      "Bash(chmod:*)",
      "Bash(shellcheck:*)"
    ],
    "defaultMode": "plan"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "example-skills@anthropic-agent-skills": true,
    "code-simplifier@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "context7@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "anthropic-agent-skills": {
      "source": {
        "source": "github",
        "repo": "anthropics/skills"
      }
    },
    "claude-plugins-official": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-plugins-official"
      }
    }
  },
  "language": "日本語"
}
```

注意: 現在の settings.json から workspace 固有の permission エントリ（`git -C /Users/takeruooyama/workspace/tts-partner` など）は除外する。

- [ ] **Step 2: plugins/installed_plugins.personal.json を作成**

`src/.claude/plugins/installed_plugins.personal.json` を以下の内容で作成:

```json
{
  "version": 2,
  "plugins": {
    "example-skills@anthropic-agent-skills": [
      {
        "scope": "user",
        "installPath": "",
        "version": "latest",
        "installedAt": "",
        "lastUpdated": ""
      }
    ],
    "code-simplifier@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "",
        "version": "latest",
        "installedAt": "",
        "lastUpdated": ""
      }
    ],
    "superpowers@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "",
        "version": "latest",
        "installedAt": "",
        "lastUpdated": ""
      }
    ],
    "context7@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "",
        "version": "latest",
        "installedAt": "",
        "lastUpdated": ""
      }
    ]
  }
}
```

注意: `installPath`, `installedAt`, `lastUpdated`, `gitCommitSha` は環境依存なので空文字列にする。Claude Code が自動的に更新する。project スコープのプラグイン（claude-api）はユーザースコープではないので除外。

- [ ] **Step 3: plugins/config.personal.json を作成**

`src/.claude/plugins/config.personal.json`:

```json
{
  "repositories": {}
}
```

- [ ] **Step 4: Commit**

```bash
git add src/.claude/settings.personal.json src/.claude/plugins/installed_plugins.personal.json src/.claude/plugins/config.personal.json
git commit -m "feat: add personal Claude Code settings files"
```

---

### Task 2: 会社用設定ファイルの作成

**Files:**

- Create: `src/.claude/settings.work.json`
- Create: `src/.claude/plugins/installed_plugins.work.json`
- Create: `src/.claude/plugins/config.work.json`

個人用をベースに、会社用として必要な差分を反映する。初期状態では個人用と同じ内容をコピーし、後から会社用の設定を調整可能にする。

- [ ] **Step 1: settings.work.json を作成**

`src/.claude/settings.work.json` — 個人用と同じ内容で作成（後から会社固有の permissions や hooks を調整可能）:

```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  },
  "includeCoAuthoredBy": false,
  "permissions": {
    "allow": [
      "WebFetch(domain:raw.githubusercontent.com)",
      "Bash(pnpm install:*)",
      "Bash(mise trust:*)",
      "Bash(mise install:*)",
      "Bash(uv sync:*)",
      "Bash(uv run pytest:*)",
      "Bash(pnpm test:*)",
      "Bash(pnpm biome check:*)",
      "Bash(uv run ruff:*)",
      "Bash(echo:*)",
      "Bash(git add:*)",
      "Bash(mise exec:*)",
      "Bash(git ls-tree:*)",
      "Bash(git log:*)",
      "Bash(gh auth status:*)",
      "Bash(gh label:*)",
      "Bash(gh label create:*)",
      "Bash(gh api:*)",
      "Bash(gh issue create:*)",
      "Bash(gh issue list:*)",
      "Bash(lefthook install:*)",
      "Bash(pnpm lefthook:*)",
      "Bash(just lint:*)",
      "Bash(just test)",
      "Bash(gh pr list:*)",
      "Bash(gh pr view:*)",
      "Bash(gh pr edit:*)",
      "Bash(git push:*)",
      "Bash(npx vitest run)",
      "Bash(git commit:*)",
      "Bash(gh issue close:*)",
      "Bash(gh run view:*)",
      "WebFetch(domain:github.com)",
      "Bash(git check-ignore:*)",
      "Bash(cat:*)",
      "Bash(git fetch:*)",
      "Bash(pnpm exec cspell:*)",
      "WebSearch",
      "Bash(pre-commit run:*)",
      "Bash(gh issue view:*)",
      "Bash(gh pr create:*)",
      "Bash(git checkout:*)",
      "Bash(gh run list:*)",
      "Bash(pnpm prettier:*)",
      "Bash(gh pr merge:*)",
      "Bash(git pull:*)",
      "Bash(git reset:*)",
      "Bash(gh pr checks:*)",
      "Bash(git branch:*)",
      "Bash(gh issue edit:*)",
      "Bash(just worktree-list:*)",
      "Bash(just worktree-create:*)",
      "Bash(just worktree-remove-with-branch:*)",
      "Bash(git rebase:*)",
      "Bash(find:*)",
      "Bash(git stash push:*)",
      "Bash(git stash:*)",
      "Bash(chmod:*)",
      "Bash(shellcheck:*)"
    ],
    "defaultMode": "plan"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "example-skills@anthropic-agent-skills": true,
    "code-simplifier@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "context7@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "anthropic-agent-skills": {
      "source": {
        "source": "github",
        "repo": "anthropics/skills"
      }
    },
    "claude-plugins-official": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-plugins-official"
      }
    }
  },
  "language": "日本語"
}
```

- [ ] **Step 2: plugins/installed_plugins.work.json を作成**

個人用と同じ内容で `src/.claude/plugins/installed_plugins.work.json` を作成。

- [ ] **Step 3: plugins/config.work.json を作成**

個人用と同じ内容で `src/.claude/plugins/config.work.json` を作成。

- [ ] **Step 4: Commit**

```bash
git add src/.claude/settings.work.json src/.claude/plugins/installed_plugins.work.json src/.claude/plugins/config.work.json
git commit -m "feat: add work Claude Code settings files"
```

---

### Task 3: dotfiles.sh に install_claude_settings を追加

**Files:**

- Modify: `scripts/dotfiles.sh:24-87` (install_dotfiles 関数の後に新関数追加、install_dotfiles の末尾で呼び出し)

- [ ] **Step 1: install_claude_settings 関数を追加**

`scripts/dotfiles.sh` の `install_dotfiles` 関数（行87）の直後に以下の関数を追加:

```bash
# Install Claude Code settings based on DOTFILES_MODE
install_claude_settings() {
  local mode="${DOTFILES_MODE:-personal}"
  local src_dir="${DOTFILES_DIR}/src/.claude"

  log_info "Installing Claude Code settings (mode: $mode)"

  local settings_src="${src_dir}/settings.${mode}.json"
  local plugins_src="${src_dir}/plugins/installed_plugins.${mode}.json"
  local config_src="${src_dir}/plugins/config.${mode}.json"

  if [[ ! -f "$settings_src" ]]; then
    log_warn "Claude Code settings not found for mode '$mode': $settings_src"
    return 0
  fi

  create_symlink "$settings_src" "${HOME}/.claude/settings.json"
  create_symlink "$plugins_src" "${HOME}/.claude/plugins/installed_plugins.json"
  create_symlink "$config_src" "${HOME}/.claude/plugins/config.json"
}
```

- [ ] **Step 2: install_dotfiles から呼び出す**

`scripts/dotfiles.sh` の `install_dotfiles` 関数末尾（行84〜87あたり、`log_success` の直前）に以下を追加:

```bash
  # Install Claude Code settings
  install_claude_settings
```

- [ ] **Step 3: 動作確認**

Run: `DRY_RUN=true ./scripts/dotfiles.sh install 2>&1 | grep -i claude`

Expected: Claude Code settings に関するドライランメッセージが表示される。

- [ ] **Step 4: Commit**

```bash
git add scripts/dotfiles.sh
git commit -m "feat: add install_claude_settings to dotfiles.sh"
```

---

### Task 4: dotfiles.sh に uninstall/status の Claude Code 対応を追加

**Files:**

- Modify: `scripts/dotfiles.sh:89-196` (uninstall_dotfiles, status_dotfiles に追加)

- [ ] **Step 1: uninstall_claude_settings 関数を追加**

`install_claude_settings` の直後に追加:

```bash
# Uninstall Claude Code settings symlinks
uninstall_claude_settings() {
  local mode="${DOTFILES_MODE:-personal}"
  local src_dir="${DOTFILES_DIR}/src/.claude"

  log_info "Uninstalling Claude Code settings"

  local targets=(
    "${HOME}/.claude/settings.json"
    "${HOME}/.claude/plugins/installed_plugins.json"
    "${HOME}/.claude/plugins/config.json"
  )

  for target in "${targets[@]}"; do
    if [[ -L "$target" ]]; then
      local link_target
      link_target=$(readlink "$target")
      # Only remove if it points to our dotfiles
      if [[ "$link_target" == "${src_dir}/"* ]]; then
        remove_symlink "$target" true
      fi
    fi
  done
}
```

- [ ] **Step 2: uninstall_dotfiles から呼び出す**

`uninstall_dotfiles` 関数の `log_success` の直前に追加:

```bash
  # Uninstall Claude Code settings
  uninstall_claude_settings
```

- [ ] **Step 3: status_claude_settings 関数を追加**

```bash
# Show status of Claude Code settings symlinks
status_claude_settings() {
  local mode="${DOTFILES_MODE:-personal}"
  local src_dir="${DOTFILES_DIR}/src/.claude"

  echo ""
  printf "%-40s %-10s %s\n" "CLAUDE CODE" "STATUS" "DETAILS"
  printf "%-40s %-10s %s\n" "----------" "------" "-------"

  local -A files=(
    ["settings.json"]="settings.${mode}.json"
    ["plugins/installed_plugins.json"]="plugins/installed_plugins.${mode}.json"
    ["plugins/config.json"]="plugins/config.${mode}.json"
  )

  for target_name in "${!files[@]}"; do
    local full_src="${src_dir}/${files[$target_name]}"
    local full_dest="${HOME}/.claude/${target_name}"
    local status details

    if [[ ! -e "$full_src" ]]; then
      status="MISSING"
      details="Source not found"
    elif [[ -L "$full_dest" ]]; then
      local target
      target=$(readlink "$full_dest")
      if [[ "$target" == "$full_src" ]]; then
        status="OK"
        details="Linked correctly (mode: $mode)"
      else
        status="WRONG"
        details="Links to: $target"
      fi
    elif [[ -e "$full_dest" ]]; then
      status="EXISTS"
      details="Not a symlink"
    else
      status="NONE"
      details="Not installed"
    fi

    printf "%-40s %-10s %s\n" ".claude/${target_name}" "$status" "$details"
  done
}
```

- [ ] **Step 4: status_dotfiles から呼び出す**

`status_dotfiles` 関数の末尾（行196の `done` の後）に追加:

```bash
  # Show Claude Code settings status
  status_claude_settings
```

- [ ] **Step 5: 動作確認**

Run: `./scripts/dotfiles.sh status 2>&1 | grep -A 10 "CLAUDE CODE"`

Expected: Claude Code 設定の状態が表示される。

- [ ] **Step 6: Commit**

```bash
git add scripts/dotfiles.sh
git commit -m "feat: add uninstall/status support for Claude Code settings"
```

---

### Task 5: doctor.sh に Claude Code ヘルスチェックを追加

**Files:**

- Modify: `scripts/lib/doctor.sh:150-189` (doctor_check_symlinks の後に新チェック追加)
- Modify: `scripts/lib/doctor.sh:305-331` (run_doctor に呼び出し追加)

- [ ] **Step 1: doctor_check_claude_settings 関数を追加**

`scripts/lib/doctor.sh` の `doctor_check_symlinks` 関数（行189）の後に追加:

```bash
doctor_check_claude_settings() {
  local mode="${DOTFILES_MODE:-personal}"
  local src_dir="${DOTFILES_DIR}/src/.claude"

  _doctor_section_header "Claude Code Settings (mode: $mode)"

  local -A files=(
    ["settings.json"]="settings.${mode}.json"
    ["plugins/installed_plugins.json"]="plugins/installed_plugins.${mode}.json"
    ["plugins/config.json"]="plugins/config.${mode}.json"
  )

  for target_name in "${!files[@]}"; do
    local full_src="${src_dir}/${files[$target_name]}"
    local full_dest="${HOME}/.claude/${target_name}"

    if [[ ! -e "$full_src" ]]; then
      doctor_check_fail ".claude/${target_name}" "Source not found: ${files[$target_name]}"
    elif [[ -L "$full_dest" ]]; then
      local target
      target=$(readlink "$full_dest")
      if [[ "$target" == "$full_src" ]]; then
        doctor_check_ok ".claude/${target_name}" "Linked correctly"
      else
        doctor_check_fail ".claude/${target_name}" "Wrong target: $target"
      fi
    elif [[ -e "$full_dest" ]]; then
      doctor_check_fail ".claude/${target_name}" "Exists but not a symlink"
    else
      doctor_check_warn ".claude/${target_name}" "Not installed"
    fi
  done
}
```

- [ ] **Step 2: run_doctor から呼び出す**

`scripts/lib/doctor.sh` の `run_doctor` 関数内（行321 `doctor_check_vscode` の後）に追加:

```bash
  doctor_check_claude_settings
```

- [ ] **Step 3: 動作確認**

Run: `./scripts/dotfiles.sh doctor 2>&1 | grep -A 10 "Claude Code"`

Expected: Claude Code Settings セクションが表示される。

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/doctor.sh
git commit -m "feat: add Claude Code settings health check to doctor"
```

---

### Task 6: End-to-end 検証

- [ ] **Step 1: install テスト（personal モード）**

```bash
./scripts/dotfiles.sh install
```

`~/.claude/settings.json` が `src/.claude/settings.personal.json` への symlink であることを確認:

```bash
readlink ~/.claude/settings.json
readlink ~/.claude/plugins/installed_plugins.json
readlink ~/.claude/plugins/config.json
```

Expected: 各ファイルが `.../.dotfiles/src/.claude/settings.personal.json` 等を指す。

- [ ] **Step 2: status テスト**

```bash
./scripts/dotfiles.sh status
```

Expected: Claude Code セクションで3つすべて `OK` と表示される。

- [ ] **Step 3: doctor テスト**

```bash
./scripts/dotfiles.sh doctor
```

Expected: Claude Code Settings セクションで3つすべて `OK` と表示される。

- [ ] **Step 4: work モードでの install テスト**

```bash
DOTFILES_MODE=work ./scripts/dotfiles.sh install
```

```bash
readlink ~/.claude/settings.json
```

Expected: `.../.dotfiles/src/.claude/settings.work.json` を指す。

- [ ] **Step 5: personal モードに戻す**

```bash
DOTFILES_MODE=personal ./scripts/dotfiles.sh install
```

- [ ] **Step 6: 冪等性テスト**

```bash
./scripts/dotfiles.sh install
./scripts/dotfiles.sh install
```

Expected: 2回目はすべて skip される（既にリンク済み）。

- [ ] **Step 7: uninstall テスト**

```bash
./scripts/dotfiles.sh uninstall
ls -la ~/.claude/settings.json
```

Expected: symlink が削除されている。

- [ ] **Step 8: re-install して元に戻す**

```bash
./scripts/dotfiles.sh install
```

- [ ] **Step 9: lint**

```bash
just lint
```

Expected: エラーなし。
