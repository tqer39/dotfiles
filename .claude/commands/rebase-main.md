---
description: main ブランチに rebase して conflict を解消
---

main ブランチに rebase して、conflict があれば解消する。

## 手順

1. 現在のブランチと状態を確認
2. `git fetch origin main` で最新を取得
3. `git rebase origin/main` を実行
4. conflict が発生した場合:
   - 競合ファイルを一覧表示
   - 各ファイルの競合内容を確認し、適切に解決
   - `git add <file>` でステージング
   - `git rebase --continue` で継続
5. rebase が完了するまで繰り返す

## 注意事項

- 未コミットの変更がある場合は先に stash するか確認する
- conflict 解決時は両方の変更の意図を理解してマージする
- 解決が難しい場合は `git rebase --abort` で中止できることを伝える
