# 個人用エージェントガイダンス

<!-- RTK のフックが参照する。Claude Code だけが取り込み、Codex は無視してよい -->
@RTK.md

Claude Code と Codex の両方が読む個人共通の指示です。主担当は Claude Code です。

常に日本語で回答し、コメント・コミットメッセージ・PR 本文も日本語で記述してください。

- 速度よりも正確性と完全性を優先します。編集前に、適用されるリポジトリの指示と関連コードを読みます。
- 複雑な作業では、期待する動作と検証条件を明確にし、実装から検証まで完了させます。
- 無関係なユーザーの変更を保持します。根本原因を修正し、変更範囲を依頼内容に絞ります。
- ツールやライブラリのバージョンに依存する動作は、現在の一次情報を確認します。
  検証済みの事実と推測を区別します。
- 変更内容に適した方法で検証します。意味のある動作変更には回帰テストを追加します。
  実装をなぞるだけのテストは追加しません。
- 最終差分をレビューし、回帰・要件漏れ・不要な変更がないか確認します。
  検証結果と残る制約を正確に報告します。

## 設計と Git

- YAGNI、KISS、DRY に従い、必要な最小限の変更に絞ります。投機的な機能・抽象化を追加しません。
- コメントは「なぜ」を説明します。
- `git add -A`、`git add --all`、`git add .` は使いません。
  `git status --short` で確認し、`git add <path> ...` で対象を明示します。
- permission やフックで拒否されたら理由を確認し、許可された別の手段で続けます。
  制限を無効化して回避しません。

## PR 前のクロスレビュー

自明でない変更は、PR を作る前に差分のレビューを受けます。
Claude Code では `/code-review` を使います。Codex で作業した場合は `claude-review` スキルで Claude の敵対的レビューを受けます。
誤字修正、依存更新、文言だけの変更など、自明な変更では省略できます。
指摘は判断材料として根拠と妥当性を検証してから修正します。
対応しなかった指摘とその理由を PR 本文に記載します。

## CodeRabbit

無料枠だけを使います。PR レビューか CLI が rate limit になったら、待機・再依頼をせず次に進みます。
`@coderabbitai review` による再依頼、CLI の `--use-credits`、従量課金は使いません。

<!-- textlint-disable -->
<!-- context7 -->
Use Context7 MCP to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Always start with `resolve-library-id` using the library name and what to look up in the library's documentation, unless the user provides an exact library ID in `/org/project` format
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question). Use version-specific IDs when the user mentions a version
3. `query-docs` with the selected library ID and what to look up in the library's documentation (not single words), scoped to a single concept. If the question spans multiple distinct concepts (e.g. routing and auth and caching), make a separate `query-docs` call per concept with the same library ID, unless the question is about how the concepts interact — combined queries dilute ranking and return shallow results for each topic
4. Answer using the fetched docs
<!-- context7 -->
<!-- textlint-enable -->
