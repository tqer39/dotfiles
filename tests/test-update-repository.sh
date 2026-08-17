#!/usr/bin/env bash
#
# Tests for install.sh's repository update path (update_repository / restore_stash).
#
# The install tests in CI all pass --ci, which skips the pull entirely, so this
# path had no coverage at all. It is where local changes are stashed and put
# back, and a regression there silently strands the user's work in the stash
# stack instead of restoring it.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_sh="${repo_root}/install.sh"

# install.sh ends by calling main, so strip that line before sourcing it. Bail
# out loudly if the entrypoint is ever rewritten, otherwise a failed match would
# silently run a full install against the developer's home directory.
if ! grep -qx 'main "\$@"' "$install_sh"; then
  echo "FAIL: install.sh no longer ends with 'main \"\$@\"'; update this test" >&2
  exit 1
fi
# Sourced from a real file rather than `source <(grep ...)`: bash 3.2, which is
# what /bin/bash still is on macOS, can close the process substitution early and
# read back only part of the script.
functions_file="$(mktemp)"
trap 'rm -f "$functions_file"' EXIT
grep -vx 'main "\$@"' "$install_sh" >"$functions_file"
# shellcheck disable=SC1090
source "$functions_file"

tests_run=0
tests_failed=0

fail() {
  echo "  FAIL: $1" >&2
  tests_failed=$((tests_failed + 1))
}

assert_equals() {
  local expected="$1" actual="$2" what="$3"
  if [[ "$expected" == "$actual" ]]; then
    return 0
  fi
  fail "$what: expected '$expected', got '$actual'"
}

stash_count() {
  git -C "$1" stash list | wc -l | tr -d ' '
}

head_sha() {
  git -C "$1" rev-parse HEAD
}

# Build an upstream repo with one commit plus a clone of it. The upstream is a
# normal (non-bare) repo so tests can commit into it directly.
make_fixture() {
  local root="$1"

  git init --quiet "${root}/upstream"
  git -C "${root}/upstream" config user.email "test@example.com"
  git -C "${root}/upstream" config user.name "dotfiles test"
  git -C "${root}/upstream" checkout --quiet -b main
  printf 'v1\n' >"${root}/upstream/tracked.txt"
  git -C "${root}/upstream" add tracked.txt
  git -C "${root}/upstream" commit --quiet -m "initial"

  git clone --quiet "${root}/upstream" "${root}/work"
  git -C "${root}/work" config user.email "test@example.com"
  git -C "${root}/work" config user.name "dotfiles test"
}

commit_upstream() {
  local root="$1" file="$2" content="$3"
  printf '%s\n' "$content" >"${root}/upstream/${file}"
  git -C "${root}/upstream" add "$file"
  git -C "${root}/upstream" commit --quiet -m "upstream: ${file}"
}

# Each test gets a fresh fixture and runs update_repository against it with the
# globals install.sh expects.
run_update() {
  local work="$1"
  DOTFILES_DIR="$work" DRY_RUN=false CI_MODE=false update_repository
}

# ------------------------------------------------------------------------------
# A clean checkout fast-forwards and leaves no stash behind
# ------------------------------------------------------------------------------
test_clean_checkout_pulls() {
  echo "test: clean checkout fast-forwards"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  commit_upstream "$root" "tracked.txt" "v2"

  local before
  before="$(stash_count "${root}/work")"
  run_update "${root}/work" >/dev/null

  assert_equals "$(head_sha "${root}/upstream")" "$(head_sha "${root}/work")" "HEAD after pull"
  assert_equals "$before" "$(stash_count "${root}/work")" "stash count"
  assert_equals "v2" "$(cat "${root}/work/tracked.txt")" "file content"
}

# ------------------------------------------------------------------------------
# Local changes survive the pull and the stash entry is cleaned up
#
# This is the regression that piled up 24 orphaned Auto-stash entries: the old
# code stashed local changes and then never restored them.
# ------------------------------------------------------------------------------
test_local_changes_restored() {
  echo "test: local changes are restored and the stash entry dropped"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  # Upstream touches a different file, so restoring cannot conflict.
  commit_upstream "$root" "other.txt" "from upstream"
  printf 'my local edit\n' >"${root}/work/tracked.txt"

  local before
  before="$(stash_count "${root}/work")"
  run_update "${root}/work" >/dev/null

  assert_equals "$(head_sha "${root}/upstream")" "$(head_sha "${root}/work")" "HEAD after pull"
  assert_equals "my local edit" "$(cat "${root}/work/tracked.txt")" "local edit preserved"
  assert_equals "from upstream" "$(cat "${root}/work/other.txt")" "upstream file present"
  assert_equals "$before" "$(stash_count "${root}/work")" "stash entry dropped"
}

# ------------------------------------------------------------------------------
# An untracked file colliding with an incoming one does not abort the pull
#
# `git stash push` without -u leaves untracked files in place, and the pull then
# dies with "untracked working tree files would be overwritten".
# ------------------------------------------------------------------------------
test_untracked_collision_does_not_block_pull() {
  echo "test: untracked collision does not block the pull"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  commit_upstream "$root" "newfile.txt" "from upstream"
  printf 'my untracked file\n' >"${root}/work/newfile.txt"

  run_update "${root}/work" >/dev/null

  assert_equals "$(head_sha "${root}/upstream")" "$(head_sha "${root}/work")" "HEAD after pull"
  # The local version could not be replayed on top, so it stays in the stash
  # rather than being thrown away.
  assert_equals "1" "$(stash_count "${root}/work")" "conflicting work kept in stash"
}

# ------------------------------------------------------------------------------
# A genuine conflict keeps the work in the stash and never writes markers
#
# Conflict markers must not reach the working tree: every file here is symlinked
# into $HOME, so a marker would break the live config.
# ------------------------------------------------------------------------------
test_conflicting_change_leaves_no_markers() {
  echo "test: conflicting change leaves no conflict markers"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  commit_upstream "$root" "tracked.txt" "upstream version"
  printf 'local version\n' >"${root}/work/tracked.txt"

  run_update "${root}/work" >/dev/null

  assert_equals "$(head_sha "${root}/upstream")" "$(head_sha "${root}/work")" "HEAD after pull"
  assert_equals "upstream version" "$(cat "${root}/work/tracked.txt")" "working tree matches upstream"
  assert_equals "1" "$(stash_count "${root}/work")" "conflicting work kept in stash"

  if grep -qE '^(<<<<<<<|>>>>>>>|=======)' "${root}/work/tracked.txt"; then
    fail "conflict markers were written into the working tree"
  fi
  # A conflicted apply must not leave the index half-merged either.
  if [[ -n "$(git -C "${root}/work" diff --name-only --diff-filter=U)" ]]; then
    fail "unmerged paths left in the index"
  fi
}

# ------------------------------------------------------------------------------
# --dry-run and --ci never touch the repository
# ------------------------------------------------------------------------------
test_dry_run_and_ci_skip_pull() {
  echo "test: dry-run and ci mode skip the pull"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  commit_upstream "$root" "tracked.txt" "v2"
  local original
  original="$(head_sha "${root}/work")"

  DOTFILES_DIR="${root}/work" DRY_RUN=true CI_MODE=false update_repository >/dev/null
  assert_equals "$original" "$(head_sha "${root}/work")" "HEAD unchanged in dry-run"

  DOTFILES_DIR="${root}/work" DRY_RUN=false CI_MODE=true update_repository >/dev/null
  assert_equals "$original" "$(head_sha "${root}/work")" "HEAD unchanged in ci mode"
}

# ------------------------------------------------------------------------------
# A diverged checkout fails instead of silently creating a merge commit,
# and the stashed work is put back before bailing out
# ------------------------------------------------------------------------------
test_diverged_checkout_fails_and_restores() {
  echo "test: diverged checkout fails and restores local changes"
  tests_run=$((tests_run + 1))
  local root
  root="$(mktemp -d)"
  make_fixture "$root"
  commit_upstream "$root" "tracked.txt" "upstream version"
  # A local commit on a different file makes the histories diverge.
  printf 'local commit\n' >"${root}/work/local.txt"
  git -C "${root}/work" add local.txt
  git -C "${root}/work" commit --quiet -m "local work"
  local local_head
  local_head="$(head_sha "${root}/work")"
  printf 'uncommitted edit\n' >"${root}/work/local.txt"

  # update_repository exits 1 on failure, so run it in a subshell.
  local status=0
  (run_update "${root}/work" >/dev/null 2>&1) || status=$?
  assert_equals "1" "$status" "exit status"
  assert_equals "$local_head" "$(head_sha "${root}/work")" "no merge commit created"
  assert_equals "uncommitted edit" "$(cat "${root}/work/local.txt")" "uncommitted edit restored"
}

echo "Running update_repository tests"
echo ""
test_clean_checkout_pulls
test_local_changes_restored
test_untracked_collision_does_not_block_pull
test_conflicting_change_leaves_no_markers
test_dry_run_and_ci_skip_pull
test_diverged_checkout_fails_and_restores

echo ""
if [[ "$tests_failed" -gt 0 ]]; then
  echo "${tests_failed} of ${tests_run} tests failed"
  exit 1
fi
echo "All ${tests_run} tests passed"
