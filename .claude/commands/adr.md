---
description: Create an Architecture Decision Record (ADR)
---

Create an ADR document in `docs/adr/` directory.

## Instructions

1. Check existing ADR files in `docs/adr/` to determine the next number (NNNN format, e.g., 0003)
2. Create a new file: `docs/adr/NNNN-<kebab-case-title>.md`
3. Follow the format below exactly

## ADR Format

```markdown
# ADR-NNNN: <Title>

## ステータス

Accepted

## コンテキスト

[Describe the background, problem, and requirements]

### 要件

- [Requirement 1]
- [Requirement 2]

## 検討した選択肢

### 選択肢 1: <Option Name>

- [Description]

### 選択肢 2: <Option Name>

- [Description]

## 決定

**<Chosen Option>** を採用する。

## 理由

| 観点 | 選択肢1 | 選択肢2 |
| ---- | ------- | ------- |
| ...  | ...     | ...     |

### 主な決定理由

1. [Reason 1]
2. [Reason 2]

## 結果

[Describe the implementation result]
```

## Topic

$ARGUMENTS
