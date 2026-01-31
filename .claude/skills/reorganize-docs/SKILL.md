---
name: reorganize-docs
description: Reorganize project documentation with bilingual (English/Japanese) structure. Use when asked to "reorganize docs", "update documentation", or "sync documentation".
---

# Reorganize Docs

Reorganize and synchronize project documentation with proper bilingual structure.

## Documentation Structure

```text
/
├── CLAUDE.md              # Claude Code guidance (English)
├── README.md              # Project introduction (English)
└── docs/
    ├── CLAUDE.ja.md       # Claude Code guidance (Japanese)
    ├── README.ja.md       # Project introduction (Japanese)
    ├── DEVELOPMENT.md     # Development guide (English)
    └── DEVELOPMENT.ja.md  # Development guide (Japanese)
```

## File Purposes

| File                   | Purpose                                       |
| ---------------------- | --------------------------------------------- |
| `CLAUDE.md`            | Claude Code guidance: overview, commands      |
| `README.md`            | Project intro: quickstart, prerequisites      |
| `docs/DEVELOPMENT.md`  | Detailed dev guide: services, troubleshooting |

## Cross-link Format

**English files:** Add after the title heading

```markdown
[🇯🇵 日本語版](path/to/file.ja.md)
```

**Japanese files:** Add after the title heading

```markdown
[🇺🇸 English](path/to/file.md)
```

### Cross-link Paths

| English File          | Japanese File             |
| --------------------- | ------------------------- |
| `CLAUDE.md`           | `docs/CLAUDE.ja.md`       |
| `README.md`           | `docs/README.ja.md`       |
| `docs/DEVELOPMENT.md` | `docs/DEVELOPMENT.ja.md`  |

English files link to Japanese with `[🇯🇵 日本語版](path/to/file.ja.md)`.
Japanese files link to English with `[🇺🇸 English](path/to/file.md)`.

## CLAUDE.md Content Requirements

1. **Project Overview**: Purpose and architecture
2. **Development Commands**: Just commands with descriptions
3. **Directory Structure**: Minimal monorepo structure
4. **GitHub Secrets**: Required secrets for CI/CD
5. **Key Technical Decisions**: Stack and tooling choices

## README.md Content Requirements

1. **Project Title and Description**
2. **Prerequisites**: Homebrew, mise, pnpm
3. **Quick Start**: Bootstrap and dev commands
4. **Documentation Links**: Links to detailed docs
5. **License**

## Workflow

1. Read existing documentation files
2. Read `justfile` to extract command documentation
3. Read `.github/workflows/` to extract required GitHub Secrets
4. Generate English `CLAUDE.md` with all required sections
5. Generate English `README.md`
6. Create `docs/` directory if not exists
7. Generate Japanese translations (`*.ja.md`)
8. Add cross-links to all files
9. Remove old `DEVELOPMENT.md` from root (if moved to docs/)
10. Run `prek run -a` to verify all linting passes

## Translation Guidelines

- Keep code blocks, commands, file paths, and URLs as-is
- Translate prose content naturally
- Maintain consistent terminology
- Keep table structure identical
- Preserve markdown formatting

## Emoji Guidelines

ドキュメント作成時は絵文字を積極的に使用する:

- 📋 セクション見出しに絵文字を追加
- ✅ リストアイテムや完了項目
- ⚠️ 警告や注意事項
- 💡 Tips やヒント
- 🔧 設定・コマンド関連
- 📁 ファイル・ディレクトリ
- 🚀 Quick Start・Getting Started
- 📖 ドキュメントリンク
- ⚡ パフォーマンス・最適化
- 🔒 セキュリティ関連

## Verification

After completion, run:

```bash
prek run -a
```

All checks must pass before considering the task complete.
