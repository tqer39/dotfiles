# ADR-0002: インストール URL の短縮化

## ステータス

Accepted

## コンテキスト

dotfiles のインストールスクリプトは GitHub の raw URL から取得・実行する設計となっている。

```bash
curl -fsSL https://raw.githubusercontent.com/tqer39/dotfiles/main/install.sh | bash
```

この URL には以下の課題がある:

- URL が長く覚えにくい
- タイプミスが発生しやすい
- ブランド性がない

### 要件

- 短く覚えやすい URL を提供すること
- `curl | bash` および `irm | iex` のパイプ実行が可能なこと
- Unix 系（macOS, Linux）と Windows の両方に対応すること

## 検討した選択肢

### 選択肢 1: CloudFlare Workers（プロキシ）

- GitHub raw コンテンツをプロキシして返却
- パスベースで Unix/Windows を分岐可能

### 選択肢 2: CloudFlare Page Rules（リダイレクト）

- 301/302 リダイレクトで GitHub raw URL へ転送
- `curl -L` でリダイレクトを追跡可能

### 選択肢 3: GitHub Pages

- 静的ファイルとしてスクリプトをホスト
- リポジトリの `gh-pages` ブランチまたは `/docs` ディレクトリを使用

## 決定

**CloudFlare Workers** を採用する。

## 理由

| 観点 | CloudFlare Workers | Page Rules | GitHub Pages |
| ---- | ------------------ | ---------- | ------------ |
| コンテンツ返却 | 直接返却 | リダイレクト | 直接返却 |
| パス分岐 | 可能 | 限定的 | 可能 |
| キャッシュ制御 | 柔軟 | なし | 限定的 |
| 追加設定 | Worker のみ | ルール追加 | ブランチ管理 |
| コスト | 無料枠で十分 | 無料 | 無料 |

### 主な決定理由

1. **コンテンツ直接返却**: リダイレクトではなくコンテンツを直接返却するため、追加の HTTP ラウンドトリップが不要
2. **柔軟なパス分岐**: 単一サブドメインで `/` と `/windows` を分岐可能
3. **キャッシュ制御**: 5分キャッシュにより GitHub API レート制限を回避
4. **シンプルな構成**: Worker 1つで完結し、リポジトリ側のブランチ管理が不要

## 結果

### URL 構造

| URL                                    | 用途                   |
| -------------------------------------- | ---------------------- |
| `https://install.tqer39.dev`           | Unix 系（install.sh）  |
| `https://install.tqer39.dev/windows`   | Windows（install.ps1） |

### 使用方法

```bash
# macOS / Linux
curl -fsSL https://install.tqer39.dev | bash

# Windows (PowerShell)
irm https://install.tqer39.dev/windows | iex
```

### CloudFlare Worker 実装

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    let targetUrl;
    if (path === '/windows' || path === '/windows/') {
      targetUrl = 'https://raw.githubusercontent.com/tqer39/dotfiles/main/install.ps1';
    } else {
      targetUrl = 'https://raw.githubusercontent.com/tqer39/dotfiles/main/install.sh';
    }

    const response = await fetch(targetUrl);
    const body = await response.text();

    return new Response(body, {
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
        'Cache-Control': 'public, max-age=300',
      },
    });
  },
};
```
