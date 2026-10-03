#!/usr/bin/env bash
# Keep the existing Unix test entry point; both installers share the same cases.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "${repo_root}/tests/test-update-repository.py" --shell bash "$@"
