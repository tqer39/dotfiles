# Local Development Setup

[🇯🇵 日本語版](./local-dev.ja.md)

Development environment setup instructions for this repository.

## Prerequisites

- macOS or Linux
- Git

## Setup

### 1. Install Development Tools

```bash
make bootstrap
```

This installs the following:

- Homebrew
- mise (version management and task runner)
- direnv (environment variable management)
- lefthook (git hooks)
- aws-vault
- cf-vault

### 2. Configure Development Environment

After restarting your shell:

```bash
mise trust
mise run setup
```

## Running Terraform

### Setting Up Credentials

The following profiles are required to run Terraform:

```bash
# Add AWS credentials
aws-vault add portfolio

# Add Cloudflare API Token
cf-vault add dotfiles
```

### Commands

```bash
# Terraform plan
mise run tf plan

# Specify a specific environment
mise run tf -chdir=prod/bootstrap init
mise run tf -chdir=prod/dns plan
```

### Bootstrap (First Time Only)

The IAM Role for GitHub Actions OIDC authentication must be created locally the first time:

```bash
mise run tf -chdir=prod/bootstrap init
mise run tf -chdir=prod/bootstrap apply
```

## Common Commands

| Command          | Description                    |
| ---------------- | ------------------------------ |
| `mise run help`  | List available commands        |
| `mise run setup` | Set up development environment |
| `mise run lint`  | Run linters                    |
| `mise run tf`    | Run Terraform commands         |
