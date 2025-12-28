set shell := ["bash", "-euo", "pipefail", "-c"]

# Environment variables
aws_profile := env("AWS_PROFILE", "default")

# Show help
help:
    @just --list

default: help

# Setup
setup: setup-mise setup-hooks
    @echo "Setup completed"

setup-mise:
    @mise install

setup-hooks:
    @prek install

# Lint
lint:
    @prek run -a

lint-hook hook:
    @prek run {{hook}}

# Clean pre-commit cache
lint-clean:
    @prek clean

# Wrap terraform with convenient -chdir handling
# Usage examples:
#   just tf -chdir=dev/bootstrap init -reconfigure
#   just tf -chdir=infra/terraform/envs/dev/bootstrap plan
#   just tf version
tf *args:
    @echo "→ make terraform-cf ARGS='{{args}}'"
    @exec make terraform-cf ARGS="{{args}}"

# mise tool management
status:
    @mise status

install:
    @mise install

update:
    @mise upgrade

# Git Worktree commands

# Worktree directory (relative to repo root)
wt_dir := "../dotfiles-worktrees"

# Create a new worktree with a new branch (branch name: name-yymmdd-xxxxxx)
wt-new name:
    #!/usr/bin/env bash
    set -euo pipefail
    suffix="$(date +%y%m%d)-$(openssl rand -hex 3)"
    branch="{{name}}-${suffix}"
    echo "→ Creating worktree: ${branch}"
    mkdir -p {{wt_dir}}
    git worktree add "{{wt_dir}}/${branch}" -b "${branch}"
    echo "✅ Worktree ready: {{wt_dir}}/${branch}"

# Create a worktree from an existing branch
wt-add branch:
    @echo "→ Creating worktree from branch: {{branch}}"
    @mkdir -p {{wt_dir}}
    git worktree add {{wt_dir}}/{{branch}} {{branch}}
    @echo "✅ Worktree ready: {{wt_dir}}/{{branch}}"

# List all worktrees
wt-list:
    @git worktree list

# Remove a worktree
wt-rm name="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{name}}" ]; then
        echo "Usage: just wt-rm <name>"
        echo ""
        echo "Available worktrees:"
        git worktree list | grep -v "(bare)" | awk '{print $1}' | xargs -I{} basename {} | sed 's/^/  /'
        exit 1
    fi
    echo "→ Removing worktree: {{name}}"
    git worktree remove {{wt_dir}}/{{name}}
    echo "✅ Worktree removed"

# Remove a worktree (force)
wt-rm-force name="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{name}}" ]; then
        echo "Usage: just wt-rm-force <name>"
        echo ""
        echo "Available worktrees:"
        git worktree list | grep -v "(bare)" | awk '{print $1}' | xargs -I{} basename {} | sed 's/^/  /'
        exit 1
    fi
    echo "→ Force removing worktree: {{name}}"
    git worktree remove --force {{wt_dir}}/{{name}}
    echo "✅ Worktree removed"

# Open worktree in VS Code
wt-code name:
    @code {{wt_dir}}/{{name}}

# Prune stale worktree references
wt-prune:
    @echo "→ Pruning stale worktree references..."
    git worktree prune
    @echo "✅ Pruned"
