# Dotfiles

このリポジトリは、git submoduleを使用して管理している公開用のdotfilesを含んでいます。これらの設定ファイルは、異なるマシン間で一貫した開発環境を維持するのに役立ちます。

## リポジトリ構造

- `src/`: すべてのdotfilesを含むディレクトリ
  - `.bash_profile`: Bashプロファイルの設定
  - `.bashrc`: Bashシェルの設定
  - `.gitconfig`: Gitの設定
  - `.gitignore`: グローバルなgitignoreルール
  - `.hyper.js`: Hyperターミナルの設定
  - `.zshrc`: Zshシェルの設定
  - `.vscode/`: VS Codeの設定と拡張機能
  - `.config/`: アプリケーション固有の設定

## 使用方法

1. このリポジトリをホームディレクトリにサブモジュールとしてクローンします：

   ```bash
   git submodule add https://github.com/yourusername/dotfiles.git
   ```

## 必要条件

- macOS（主要な開発環境）
- zsh（デフォルトシェル）
- Git

## ドキュメント

英語版のドキュメントについては、[README.md](../README.md)を参照してください。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](../LICENSE)ファイルを参照してください。
