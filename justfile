set shell := ["bash", "-euo", "pipefail", "-c"]

# Environment variables
aws_profile := env("AWS_PROFILE", "default")

# Show help
default:
    @just --list

# Setup
setup: setup-mise setup-direnv setup-hooks
    @echo "Setup completed"

setup-mise:
    @mise install

setup-direnv:
    @direnv allow .

setup-hooks:
    @prek install

# Lint
lint:
    @prek run -a

lint-hook hook:
    @prek run {{hook}}

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
