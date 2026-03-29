---
name: sync-packages
description: >-
  パッケージの追加・削除・インストール・セットアップ時に全プラットフォーム（macOS/Linux/Windows）の
  整合性を確保する。「〜を追加して」「〜をインストールして」「〜を入れて」「〜をセットアップ」
  「〜を削除して」「Brewfile に〜」「dotfiles に〜を追加」等のパッケージ変更リクエストで必ず実行。
  CLI ツール、GUI アプリ、言語ランタイム、NPM パッケージ、VS Code 拡張の追加・削除すべてに適用。
---

# Sync Packages

パッケージを追加・削除する際に、全プラットフォーム（macOS, Linux, Windows）間の整合性を確保するスキル。

**パッケージを追加・削除する場合は、必ずこのスキルに従って全プラットフォームの整合性を確認・更新すること。**

## 対象ファイル

- `config/packages/Brewfile` — macOS/Linux CLI ツール + macOS cask (GUI)
- `config/packages/apt-packages.txt` — Ubuntu/Debian システム依存パッケージ
- `scripts/installers/apt.sh` — Linux GUI アプリ個別インストーラー（snap/flatpak/.deb）
- `install.ps1` — Windows: Scoop / WinGet / NPM / PowerShell モジュール
- `install.sh` — 全 OS のセットアップエントリーポイント（Obsidian 個別インストール含む）
- `src/.config/mise/config.toml` — mise 共通設定（node LTS ベース）
- `src/.config/mise/config.personal.toml` — Personal: AI CLI ツール（NPM）+ node バージョン
- `src/.config/mise/config.work.toml` — Work: 最小構成（空）
- `mise.toml`(ルート) — リポジトリローカル開発ツール(terraform / trivy / biome)
- `Brewfile`(ルート) — CI/最小構成用(`config/packages/Brewfile` のサブセット)
- `src/.vscode/extensions.json` — VS Code 拡張機能（全 OS 共通）

## パッケージ種別判定フロー

1. **CLI ツール** → 全プラットフォーム共通セクションへ
2. **GUI アプリ** → プラットフォーム別セクションへ
3. **言語ランタイム・開発ツール** → mise 設定へ
4. **NPM グローバルパッケージ** → mise config.personal.toml + install.ps1 NPM
5. **VS Code 拡張** → extensions.json へ
6. **OS 専用** → 該当 OS のファイルのみ

## パッケージ種別と配置先

### CLI ツール（全プラットフォーム共通）

- **macOS/Linux**: `config/packages/Brewfile` に `brew "name"` で追加
- **Windows**: `install.ps1` の `Install-ScoopPackages` 内 `$packages` 配列に追加

サードパーティの brew パッケージは `tap` が必要:

```ruby
# Brewfile
tap "owner/repo"
brew "owner/repo/name"  # 説明
```

Scoop でデフォルト bucket にないパッケージは、`Install-ScoopPackages` 内で bucket 追加済みか確認:

```powershell
# install.ps1 - 既存の bucket 追加
scoop bucket add extras 2>$null
scoop bucket add nerd-fonts 2>$null
```

### GUI アプリ（クロスプラットフォーム）

- **macOS**: `Brewfile` の `if OS.mac?` 内に `cask "name"` で追加
- **Linux**: `apt.sh` に `install_xxx()` 関数を追加
- **Windows**: `install.ps1` の `Install-WingetPackages` 内 `$packages` 配列に追加

Linux の GUI アプリは snap/flatpak/.deb のいずれかでインストールする。`apt.sh` の既存関数パターンを参照:

```bash
# apt.sh - 新規 GUI アプリ関数テンプレート
install_xxx() {
  log_info "Installing XXX..."

  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "mint" && "$os" != "linux" ]]; then
    log_warn "XXX installation is only available on Ubuntu/Debian/Mint. Skipping..."
    return 0
  fi

  if command -v xxx &>/dev/null; then
    log_debug "XXX is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install XXX"
    return 0
  fi

  # snap → flatpak → .deb の優先順位でインストール
  if command -v snap &>/dev/null; then
    log_info "Installing XXX via Snap..."
    sudo snap install xxx
  elif command -v flatpak &>/dev/null; then
    log_info "Installing XXX via Flatpak..."
    flatpak install -y flathub org.example.XXX
  else
    log_warn "Neither snap nor flatpak available. Skipping XXX installation."
    return 0
  fi

  log_success "XXX installed"
}
```

Linux GUI アプリを追加したら、`install.sh` の `main()` 関数内から呼び出しを追加する。Server モードチェック内に配置すること:

```bash
# install.sh - main() 内
if [[ "${SERVER_MODE:-false}" != "true" ]]; then
  install_xxx  # ← 追加
fi
```

WinGet パッケージは `Publisher.AppName` 形式:

```powershell
# install.ps1 - Install-WingetPackages 内
$packages = @(
    "Microsoft.VisualStudioCode",
    "Publisher.NewApp"           # ← 追加
)
```

### macOS 専用アプリ

`Brewfile` の `if OS.mac?` ブロックに `cask` で追加。他プラットフォームへの追加は不要。

```ruby
if OS.mac?
  cask "raycast"
  cask "karabiner-elements"
end
```

### Linux 専用パッケージ

- **システム依存パッケージ**: `apt-packages.txt` に1行追加
- **GUI アプリ**: `apt.sh` に `install_xxx()` 関数を追加

Brewfile で Linux 専用の brew パッケージは条件付きで追加:

```ruby
brew "xsel" if OS.linux?  # clipboard support for Linux
```

### Windows 専用アプリ

`install.ps1` の該当関数（Scoop or WinGet）に追加。

### 言語ランタイム・開発ツール

- **グローバル共通**(node LTS 等) → `src/.config/mise/config.toml`
- **Personal 用ツール**(AI CLI 等) → `src/.config/mise/config.personal.toml`
- **Work 用ツール** → `src/.config/mise/config.work.toml`
- **リポジトリローカル**(terraform 等) → `mise.toml`(ルート)

mise はプラットフォーム差を吸収するため、OS 固有の対応は不要。

**注意**: ルートの `mise.toml` はリポジトリ開発用。グローバルツールの追加先は `src/.config/mise/` 配下の設定ファイル。

### NPM グローバルパッケージ

- **macOS/Linux**: `src/.config/mise/config.personal.toml` に追加
- **Windows**: `install.ps1` の `Install-NpmPackages` 内 `$npmPackages` 配列に追加

```toml
# src/.config/mise/config.personal.toml
[tools]
"npm:@scope/package-name" = "latest"
```

```powershell
# install.ps1 - Install-NpmPackages 内
$npmPackages = @(
    "vercel",
    "@google/gemini-cli",
    "@new/package"          # ← 追加
)
```

### フォントパッケージ

プラットフォームごとに名前・インストール方法が異なる:

- **macOS**: `Brewfile` に `cask "font-hackgen-nerd"`
- **Windows**: Scoop に `"Hack-NF"`（`nerd-fonts` bucket が必要）
- **Linux**: `apt-packages.txt` に `fonts-noto-cjk`

HackGen フォントは Windows では手動インストールが必要（Scoop に未登録）。

### PowerShell モジュール（Windows 専用）

`install.ps1` の `Install-PowerShellModules` 関数内に追加:

```powershell
Install-Module -Name ModuleName -Scope CurrentUser -Force -AllowClobber
```

### VS Code 拡張機能

`src/.vscode/extensions.json` の `recommendations` 配列に追加:

```json
{
  "recommendations": [
    "publisher.extension-id"
  ]
}
```

macOS/Linux は `scripts/installers/vscode.sh`、Windows は `install.ps1` の `Install-VSCodeExtensions` がこのファイルを読む。

## Work/Personal モード

Personal パッケージ（`--work` フラグで除外される）の配置ルール:

- **macOS Brewfile**: `if OS.mac? && ENV['WORK_MODE'] != 'true'` ブロック
- **Linux apt.sh**: 各 `install_xxx()` 関数内で `WORK_MODE` チェック
- **Windows Scoop**: `if (-not $Work) { $packages += "..." }` ブロック
- **Windows WinGet**: `if (-not $Work) { $packages += "..." }` ブロック
- **mise**: `config.personal.toml`（Work 時は `config.work.toml` が使用される）

Personal パッケージ例: orbstack / spotify / discord / podman-desktop / AI CLI ツール。

## Server モード

`--server` フラグで GUI アプリをスキップ。以下が除外対象:

- Linux: albert / 1password / vscode / ghostty / wezterm / spotify / discord / obsidian / podman-desktop
- 日本語フォント・入力メソッド
- VS Code 拡張機能

GUI アプリを追加する場合は、`install.sh` の `SERVER_MODE` チェック内に配置すること。
`apt.sh` で `SERVER_MODE` をチェックしている箇所: `install_apt_packages`（日本語環境）, `install_podman`（Podman Desktop）。

## 手順

### パッケージ追加の場合

1. **種別を判定**: CLI / GUI / 言語ランタイム / NPM / VS Code 拡張 / OS 専用
2. **上記マッピングに従い、該当する全ファイルにパッケージを追加**
3. **各ファイルの既存パターンに従う**:
   - `Brewfile`: セクションコメントに合わせて適切な位置に挿入し、インラインコメントで用途を記述
   - `install.ps1`: 該当関数内の `$packages` 配列に追加
   - `apt.sh`: 既存の `install_xxx()` 関数パターンに従って関数を追加
   - `mise`: 正しい設定ファイルに `[tools]` セクションで追加
   - `extensions.json`: `recommendations` 配列に追加
4. **前提条件を確認**: Homebrew `tap` や Scoop `bucket` が必要か
5. **Personal パッケージの場合**: Work モード除外ブロックに配置
6. **GUI アプリの場合**: Server モード除外を考慮
7. **ルート `Brewfile` への追加が必要か確認**（CI/最小構成で必要なパッケージのみ）

### パッケージ削除の場合

1. 全対象ファイルから該当パッケージのエントリを削除
2. `apt.sh` の場合は関数本体と `install.sh` からの呼び出しの両方を削除
3. `extensions.json` から VS Code 拡張を削除（該当する場合）
4. mise 設定から削除（該当する場合）
5. 不要になった `tap` / `bucket` があれば削除

## チェック項目

- [ ] CLI ツールが Brewfile と install.ps1 Scoop の両方に存在するか
- [ ] GUI アプリが macOS (cask) / Linux (apt.sh) / Windows (WinGet) の全てに対応しているか
- [ ] Personal パッケージが全プラットフォームで Work モード除外されているか
- [ ] 各ファイルのコメントスタイル・セクション構造が既存パターンと一致しているか
- [ ] `install.sh` の `main()` から新規関数が呼び出されているか（Linux GUI アプリの場合）
- [ ] VS Code 拡張が必要なツールの場合、`extensions.json` に追加されているか
- [ ] Homebrew `tap` / Scoop `bucket` が必要な場合、追加されているか
- [ ] mise の正しい設定ファイルに追加されているか（ルート `mise.toml` ではなく `src/.config/mise/` 配下）
- [ ] Server モード対応が必要な GUI アプリの場合、`SERVER_MODE` チェックが入っているか
- [ ] フォントの場合、プラットフォームごとの名前の違いを考慮しているか

## 検証

```bash
just lint
```

すべてのチェックが Passed になるまで修正を繰り返す。

変更後は `sync-install-docs` スキルも実行してドキュメントの整合性を確認すること。
