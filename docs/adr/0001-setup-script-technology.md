# ADR-0001: セットアップスクリプトの技術選定

## ステータス

Accepted

## コンテキスト

dotfiles リポジトリにおいて、マルチプラットフォーム（macOS, Linux Ubuntu, Windows）対応のセットアップスクリプトを実装する必要がある。

### 要件

- `curl` でスクリプトを取得・実行してセットアップを開始できること
- 冪等性を担保すること（何度実行しても同じ結果になる）
- macOS, Linux (Ubuntu), Windows をサポートすること
- オプションで開発環境のセットアップも実行可能なこと

## 検討した選択肢

### 選択肢 1: Shell Script + PowerShell

- Unix 系は Bash スクリプト、Windows は PowerShell スクリプトで実装
- 冪等性は自前で実装

### 選択肢 2: Ansible

- YAML ベースの宣言的な構成管理ツール
- 冪等性は組み込み機能として提供

## 決定

**Shell Script + PowerShell** を採用する。

## 理由

| 観点 | Shell Script | Ansible |
| ---- | ------------ | ------- |
| curl パイプ実行 | 可能 | 不可（事前インストール必要） |
| Windows ネイティブ対応 | PowerShell で対応可能 | WSL 必須、ネイティブ非対応 |
| 依存関係 | bash/zsh のみ | Python + Ansible が必要 |
| 冪等性 | 自前実装が必要 | 組み込み機能 |
| 学習コスト | 低い | 中程度 |

### 主な決定理由

1. **curl パイプ実行の要件**: `curl -fsSL URL | bash` で即座に実行できることが要件であり、Ansible では事前インストールが必要なため不適
2. **Windows ネイティブ対応**: Ansible は Windows をコントロールノードとしてサポートしておらず、WSL が必須となる
3. **依存関係の最小化**: 新しい環境では Python や Ansible がインストールされていない可能性が高い
4. **規模の適切性**: dotfiles 程度の規模では Ansible のオーバーヘッドが大きい

### Ansible が適切なケース（参考）

- 複数サーバーへの一括デプロイ
- 複雑なインフラ構成管理
- チームで共有する本番環境の管理

## 結果

- `install.sh`: Unix 系（macOS, Linux）のエントリーポイント
- `install.ps1`: Windows PowerShell のエントリーポイント
- `scripts/lib/`: 冪等性を担保するユーティリティライブラリ
  - `symlink.sh`: シンボリックリンクの冪等な作成・削除
  - `utils.sh`: OS 判定、コマンド存在確認
  - `log.sh`: ログ出力

冪等性は以下の方法で担保:

- シンボリックリンク: 既に正しいリンクが存在する場合はスキップ
- パッケージ: インストール済みの場合はスキップ
- バックアップ: 既存ファイルは `~/.dotfiles_backup/` に退避
