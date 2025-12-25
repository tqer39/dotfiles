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
- mise (version management)
- just (task runner)
- direnv (environment variable management)
- prek (pre-commit hooks)
- aws-vault
- cf-vault

### 2. Configure Development Environment

After restarting your shell:

```bash
just setup
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
just tf plan

# Specify a specific environment
just tf -chdir=prod/bootstrap init
just tf -chdir=prod/dns plan
```

### Bootstrap (First Time Only)

The IAM Role for GitHub Actions OIDC authentication must be created locally the first time:

```bash
just tf -chdir=prod/bootstrap init
just tf -chdir=prod/bootstrap apply
```

## Common Commands

| Command      | Description                      |
| ------------ | -------------------------------- |
| `just help`  | List available commands          |
| `just setup` | Set up development environment   |
| `just lint`  | Run linters                      |
| `just tf`    | Run Terraform commands           |
