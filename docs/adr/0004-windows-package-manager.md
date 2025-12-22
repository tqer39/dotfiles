# ADR-0004: Windows パッケージマネージャーの選定

## ステータス

Accepted

## コンテキスト

Windows 環境での dotfiles セットアップにおいて、開発ツールやアプリケーションを自動インストールするためのパッケージマネージャーを選定する必要がある。macOS での Homebrew、Linux での apt に相当する役割を担う。

### 要件

- コマンドラインからの自動インストールが可能であること
- 開発ツール (git, gh, starship など) が利用可能であること
- GUI アプリケーションもインストールできること
- 管理者権限なしでも利用可能であること (望ましい)
- 安定性と信頼性があること

## 検討した選択肢

### 選択肢 1: Scoop

- ユーザーディレクトリにインストール (管理者権限が不要)
- ポータブルなインストール
- シンプルなコマンドライン
- バケット (リポジトリ) による拡張
- アンインストールがクリーン
- 主に CLI ツール向け

### 選択肢 2: winget (Windows Package Manager)

- Microsoft 公式ツール
- Windows 10/11 に標準搭載
- Microsoft Store と統合
- GUI アプリケーションに強い
- 管理者権限が必要な場合あり

### 選択肢 3: Chocolatey

- 長年の実績
- 豊富なパッケージ
- 管理者権限が必要
- 企業向け有料版あり

## 決定

**Scoop と winget を併用**する。

- **Scoop**: CLI ツール (git, gh, starship) を優先的にインストール
- **winget**: GUI アプリケーション (VS Code, Raycast) をインストール

## 理由

| 観点 | Scoop | winget | Chocolatey |
| ---- | ----- | ------ | ---------- |
| 管理者権限 | 不要 | 場合による | 必要 |
| CLI ツール | ◎ | ○ | ◎ |
| GUI アプリ | △ | ◎ | ◎ |
| インストール先 | ユーザーディレクトリ | システム全体 | システム全体 |
| アンインストール | ◎ (クリーン) | ○ | ○ |
| 標準搭載 | × | ◎ | × |
| バージョン管理 | ◎ | ○ | ○ |
| 学習コスト | 低 | 低 | 中 |

### 主な決定理由

1. **管理者権限が不要**: Scoop はユーザーディレクトリにインストールするため、管理者権限なしで利用可能
2. **クリーンなインストール**: Scoop は各アプリを独立したディレクトリに配置し、アンインストールが確実
3. **バージョン切り替え**: Scoop は複数バージョンの切り替えが容易
4. **GUI アプリには winget を使用**: Microsoft Store と統合されており、GUI アプリのインストールに適している
5. **併用による最適化**: 各ツールの得意分野を活かすことで、最適なインストール体験を提供

## 結果

`install.ps1` に以下の関数を実装:

```powershell
# Scoop のインストール (未インストールの場合)
function Install-Scoop {
    # Scoop を自動インストール
}

# Scoop パッケージのインストール
function Install-ScoopPackages {
    $packages = @("git", "gh", "starship")
    # extras バケットを追加
    scoop bucket add extras
    # パッケージをインストール
}

# winget パッケージのインストール (GUI アプリ)
function Install-WingetPackages {
    $packages = @("Microsoft.VisualStudioCode", "Raycast.Raycast")
    # GUI アプリをインストール
}
```

インストール順序:

1. Scoop をインストール
2. Scoop で CLI ツールをインストール
3. winget で GUI アプリをインストール
