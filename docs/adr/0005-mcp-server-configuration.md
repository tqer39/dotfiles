# ADR-0005: MCP サーバー設定の管理方法

## ステータス

Accepted

## コンテキスト

VS Code と Claude Code の両方で MCP（Model Context Protocol）サーバーを使用している。MCP サーバーの設定を dotfiles で管理し、複数の環境で共有したい。

### 要件

- MCP サーバー設定を git で管理する
- VS Code と Claude Code の両方で設定を共有する
- ユーザー固有のメタデータ（userID 等）は管理対象外とする

## 検討した選択肢

### 選択肢 1: ~/.claude.json で一元管理

- VS Code と Claude Code の両方が `~/.claude.json` を参照
- シンボリックリンクで `src/.claude.json` を `~/.claude.json` に配置

### 選択肢 2: ツールごとに設定ファイルを分離

- VS Code: `src/.vscode/mcp.json` → `~/.vscode/mcp.json` にシンボリックリンク
- Claude Code: プロジェクトルートに `.mcp.json` を配置

### 選択肢 3: ~/.mcp.json で共通管理

- 共通の `~/.mcp.json` を作成し、両ツールから参照

## 決定

**選択肢 2: ツールごとに設定ファイルを分離** を採用する。

## 理由

| 観点 | 選択肢 1 | 選択肢 2 | 選択肢 3 |
| ---- | -------- | -------- | -------- |
| Claude Code の仕様適合 | ❌ userID 等のメタデータも含まれる | ✅ プロジェクト単位で設定可能 | ❌ `~/.mcp.json` は読み取られない |
| VS Code の仕様適合 | ❌ 参照しない | ✅ 公式サポート | ❌ 参照しない |
| 設定の分離 | ❌ メタデータが混在 | ✅ 完全分離 | ✅ 分離可能 |

### 主な決定理由

1. **Claude Code は `~/.mcp.json` を読み取らない**: ユーザー設定は `~/.claude.json`、プロジェクト設定は `<project>/.mcp.json` のみ対応
2. **VS Code は独自の設定パス**: `~/.vscode/mcp.json` または `<project>/.vscode/mcp.json` を使用
3. **関心の分離**: ツールごとに設定ファイルを分けることで、将来的な変更にも柔軟に対応可能

## 結果

### VS Code

- `src/.vscode/mcp.json` を作成
- `config/platform-files.conf` でシンボリックリンクを設定:
  ```
  .vscode/mcp.json:VSCODE_USER_DIR/mcp.json:all
  ```

### Claude Code

- プロジェクトルートに `.mcp.json` を配置
- シンボリックリンクは使用しない（プロジェクトスコープの設定として機能）
- `~/.claude.json` は `.gitignore` に追加（ユーザー固有のメタデータを除外）

### 注意事項

- Claude Code の MCP サーバーは、そのプロジェクトディレクトリで `claude` を起動した場合のみ有効
- 全プロジェクトで MCP サーバーを使用したい場合は、各プロジェクトに `.mcp.json` を配置するか、`~/.claude.json` を直接編集する必要がある
