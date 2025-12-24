---
description: Translate documentation between English and Japanese with cross-links
---

Translate documentation files and add cross-links between English and Japanese versions.

## Rules

1. **README.md** (root): English only, Japanese version at `docs/README.ja.md`
2. **CLAUDE.md** (root): English only, Japanese version at `docs/CLAUDE.ja.md`
3. **docs/*.md**: English, Japanese version at `docs/*.ja.md`
4. **docs/*.ja.md**: Japanese, English version at `docs/*.md` (without `.ja`)

## Cross-link Format

Add at the top of each file (after title):

**English version:**

```markdown
[🇯🇵 日本語版](./filename.ja.md)
```

**Japanese version:**

```markdown
[🇺🇸 English](./filename.md)
```

**For README.md:**

```markdown
[🇯🇵 日本語版](docs/README.ja.md)
```

**For docs/README.ja.md:**

```markdown
[🇺🇸 English](../README.md)
```

**For CLAUDE.md:**

```markdown
[🇯🇵 日本語版](docs/CLAUDE.ja.md)
```

**For docs/CLAUDE.ja.md:**

```markdown
[🇺🇸 English](../CLAUDE.md)
```

## Instructions

1. Read the source file
2. Translate the content (keep code blocks, commands, and file paths as-is)
3. Add cross-link to both source and target files
4. Write the translated file
5. Run `pre-commit run --all-files` to verify

## Target

$ARGUMENTS
