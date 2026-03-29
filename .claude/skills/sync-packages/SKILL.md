---
name: sync-packages
description: パッケージの追加・削除時に全プラットフォーム（macOS/Linux/Windows）の整合性を確保する。パッケージを変更したら必ず実行。
---

# Sync Packages

パッケージを追加・削除する際に、全プラットフォーム（macOS, Linux, Windows）間の整合性を確保するスキル。

## 重要

**パッケージを追加・削除する場合は、必ずこのスキルに従って全プラットフォームの整合性を確認・更新すること。**

## 対象ファイル

| ファイル                           | 管轄                                                     |
| ---------------------------------- | -------------------------------------------------------- |
| `config/packages/Brewfile`         | macOS/Linux CLI ツール + macOS cask (GUI)                |
| `config/packages/apt-packages.txt` | Ubuntu/Debian システム依存パッケージ                     |
| `scripts/installers/apt.sh`        | Linux GUI アプリ個別インストーラー                       |
| `install.ps1`                      | Windows: Scoop, WinGet, NPM, PowerShell                  |
| `install.sh`                       | macOS: Obsidian 等の個別インストール                     |
| `mise.toml`                        | 言語ランタイム・開発ツール（全 OS 共通）                 |
| `Brewfile`（ルート）               | CI/最小構成用（`config/packages/Brewfile` のサブセット） |

## パッケージ種別と配置先マッピング

### CLI ツール（全プラットフォーム共通）

| macOS/Linux                             | Windows                                     |
| --------------------------------------- | ------------------------------------------- |
| `config/packages/Brewfile` に `brew ""` | `install.ps1` の `$packages` 配列（Scoop）  |

例: git / gh / starship / fzf / eza / bat / ripgrep / jq / mise / just / prek / tailscale。

### GUI アプリ

| macOS                                     | Linux                                   | Windows                                  |
| ----------------------------------------- | --------------------------------------- | ---------------------------------------- |
| `Brewfile` に `cask ""` (`if OS.mac?` 内) | `apt.sh` に `install_xxx()` 関数を追加  | `install.ps1` の WinGet `$packages` 配列 |

例: VS Code, 1Password, Ghostty, Obsidian。

### macOS 専用アプリ

`Brewfile` の `if OS.mac?` ブロックに `cask` で追加する。他プラットフォームへの追加は不要。

例: Raycast, Karabiner-Elements, Hammerspoon。

### Linux 専用アプリ

`apt.sh` に専用関数を追加し、`install.sh` の `main()` から呼び出す。

例: Albert（Linux のみのランチャー）。

### Windows 専用アプリ

`install.ps1` の該当関数（Scoop or WinGet）に追加する。

例: MobaXterm, PowerToys。

### 言語ランタイム・開発ツール

`mise.toml` に追加する。プラットフォーム固有の対応は不要（mise が吸収）。

### NPM グローバルパッケージ

| macOS/Linux                 | Windows                                                       |
| --------------------------- | ------------------------------------------------------------- |
| `mise.toml` で管理（推奨）  | `install.ps1` の `Install-NpmPackages` の `$npmPackages` 配列 |

## Work/Personal モード

Personal パッケージ（`--work` フラグで除外される）の配置ルール:

| プラットフォーム | 配置場所                                                           |
| ---------------- | ------------------------------------------------------------------ |
| macOS            | `Brewfile` の `if OS.mac? && ENV['WORK_MODE'] != 'true'` ブロック  |
| Linux            | `apt.sh` の各関数内で `WORK_MODE` チェック                         |
| Windows Scoop    | `install.ps1` の `if (-not $Work) { $packages += "..." }` ブロック |
| Windows WinGet   | `install.ps1` の `if (-not $Work) { $packages += "..." }` ブロック |

対象パッケージ: orbstack, spotify, discord, podman-desktop。

## 手順

### パッケージ追加の場合

1. パッケージの種別を判定する（CLI / GUI / 言語ランタイム / OS 専用）。
2. 上記マッピングに従い、該当する全ファイルにパッケージを追加する。
3. 各ファイルの既存パターンに従う:
   - `Brewfile`: セクションコメントに合わせて適切な位置に挿入し、インラインコメントで用途を記述する。
   - `install.ps1` Scoop: `$packages` 配列に追加する。
   - `install.ps1` WinGet: `$packages` 配列に WinGet ID 形式（`Publisher.AppName`）で追加する。
   - `apt.sh`: 既存の `install_xxx()` 関数パターンに従って関数を追加する。
4. Personal パッケージの場合は Work モード除外ブロックに配置する。
5. Server モード（`--server`）で除外すべき GUI アプリは `SERVER_MODE` チェックを追加する。
6. ルート `Brewfile` への追加が必要か確認する（CI/最小構成で必要なパッケージのみ）。

### パッケージ削除の場合

1. 全対象ファイルから該当パッケージのエントリを削除する。
2. `apt.sh` の場合は関数本体と `install.sh` からの呼び出しの両方を削除する。

## チェック項目

- CLI ツールが Brewfile と install.ps1 Scoop の両方に存在するか。
- GUI アプリが macOS (cask) / Linux (apt.sh) / Windows (WinGet) の全てに対応しているか。
- Personal パッケージが全プラットフォームで Work モード除外されているか。
- 各ファイルのコメントスタイル・セクション構造が既存パターンと一致しているか。
- `install.sh` の `main()` から新規関数が呼び出されているか（Linux GUI アプリの場合）。

## 検証

```bash
just lint
```

すべてのチェックが Passed になるまで修正を繰り返す。

変更後は `sync-install-docs` スキルも実行してドキュメントの整合性を確認すること。
