#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# driver.sh - Sandboxed harness for driving this dotfiles repo
# ------------------------------------------------------------------------------
# Every command runs with HOME pointed at a throwaway sandbox directory, so
# install/uninstall never touch the real home directory. All of the repo's
# code paths (expand_path, BACKUP_DIR, create_symlink, doctor) read $HOME, so
# overriding it is a complete sandbox.
#
# Usage: .claude/skills/run-dotfiles/driver.sh <command> [args]
# Run `driver.sh help` for the command list.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

SANDBOX_ROOT="${SANDBOX_ROOT:-/tmp/dotfiles-sandbox}"
SANDBOX_HOME="${SANDBOX_HOME:-${SANDBOX_ROOT}/home}"

REAL_HOME="$HOME"

# ------------------------------------------------------------------------------
# Safety: never let the sandbox be (or contain) the real home directory
# ------------------------------------------------------------------------------
assert_sandbox_safe() {
  case "$SANDBOX_HOME" in
    "$REAL_HOME" | "$REAL_HOME"/..* | / | "")
      echo "REFUSING: SANDBOX_HOME ('$SANDBOX_HOME') is unsafe" >&2
      exit 1
      ;;
  esac
  if [[ "$REAL_HOME" == "$SANDBOX_HOME"/* ]]; then
    echo "REFUSING: real HOME lives inside SANDBOX_HOME" >&2
    exit 1
  fi
}

prepare_sandbox() {
  assert_sandbox_safe
  mkdir -p "$SANDBOX_HOME"
}

# Reset the sandbox to an empty home directory.
reset_sandbox() {
  assert_sandbox_safe
  rm -rf "$SANDBOX_HOME"
  mkdir -p "$SANDBOX_HOME"
}

# Run a command with HOME (and friends) redirected at the sandbox.
# The OS override is passed through so a single machine can exercise the
# macOS / ubuntu / windows branches of platform-files.conf.
#
# CWD is the sandbox home on purpose: mise walks *up* from the working
# directory, so running inside the repo makes it find an untrusted mise.toml
# in an ancestor directory and fail. Nothing here reads CWD -- dotfiles.sh
# locates itself via BASH_SOURCE and install.sh via DOTFILES_DIR.
in_sandbox() {
  prepare_sandbox
  cd "$SANDBOX_HOME"
  env \
    HOME="$SANDBOX_HOME" \
    XDG_CONFIG_HOME="${SANDBOX_HOME}/.config" \
    APPDATA="${SANDBOX_HOME}/AppData/Roaming" \
    GIT_CONFIG_GLOBAL="${SANDBOX_HOME}/.gitconfig" \
    ${DOTFILES_OS_OVERRIDE:+DOTFILES_OS_OVERRIDE="$DOTFILES_OS_OVERRIDE"} \
    ${DOTFILES_MODE:+DOTFILES_MODE="$DOTFILES_MODE"} \
    ${LOG_LEVEL:+LOG_LEVEL="$LOG_LEVEL"} \
    ${DRY_RUN:+DRY_RUN="$DRY_RUN"} \
    bash "$@"
}

# ------------------------------------------------------------------------------
# Observation helpers
# ------------------------------------------------------------------------------

# Print every symlink under the sandbox home that points back into this repo.
list_links() {
  assert_sandbox_safe
  if [[ ! -d "$SANDBOX_HOME" ]]; then
    echo "(sandbox not created yet)"
    return 0
  fi
  local count=0
  while IFS= read -r link; do
    printf '%s -> %s\n' "${link#"$SANDBOX_HOME"/}" "$(readlink "$link")"
    count=$((count + 1))
  done < <(find "$SANDBOX_HOME" -type l | sort)
  echo "--- $count symlink(s) in $SANDBOX_HOME"
}

# Assert a symlink exists and resolves into the repo. Used by `smoke`.
assert_link() {
  local rel="$1"
  local path="${SANDBOX_HOME}/${rel}"
  if [[ ! -L "$path" ]]; then
    echo "FAIL: not a symlink: $rel" >&2
    return 1
  fi
  local target
  target=$(readlink "$path")
  if [[ "$target" != "${REPO_DIR}/"* ]]; then
    echo "FAIL: $rel points outside the repo: $target" >&2
    return 1
  fi
  echo "ok   $rel -> ${target#"$REPO_DIR"/}"
}

assert_absent() {
  local rel="$1"
  local path="${SANDBOX_HOME}/${rel}"
  if [[ -L "$path" ]]; then
    echo "FAIL: symlink still present after uninstall: $rel" >&2
    return 1
  fi
  echo "ok   $rel removed"
}

# ------------------------------------------------------------------------------
# Commands
# ------------------------------------------------------------------------------

cmd_status()    { in_sandbox "${REPO_DIR}/scripts/dotfiles.sh" status; }
cmd_install()   { in_sandbox "${REPO_DIR}/scripts/dotfiles.sh" install; }
cmd_uninstall() { in_sandbox "${REPO_DIR}/scripts/dotfiles.sh" uninstall; }

# doctor is the fragile one: doctor.sh:294 does a bare `node_version=$(mise
# current node ...)`, so under `set -e` any nonzero exit from mise kills the
# whole run mid-section with no summary and status 1. in_sandbox already moves
# CWD out of the repo (see above) so mise stops tripping over untrusted
# ancestor configs; trusting explicitly covers the rest.
cmd_doctor() {
  prepare_sandbox
  trust_mise_configs
  in_sandbox "${REPO_DIR}/scripts/dotfiles.sh" doctor
}

# Trust every mise config the sandbox might load. After `install`, the sandbox's
# own ~/.config/mise/config.toml is a symlink into the repo -- and mise keys
# trust on the path it loaded the file *from*, not on the resolved target, so
# trusting the repo copy is not enough.
trust_mise_configs() {
  command -v mise > /dev/null 2>&1 || return 0
  local cfg
  for cfg in \
    "${REPO_DIR}/mise.toml" \
    "${SANDBOX_HOME}/.config/mise/config.toml" \
    "${SANDBOX_HOME}/.config/mise/config.personal.toml" \
    "${SANDBOX_HOME}/.config/mise/config.work.toml"; do
    [[ -e "$cfg" ]] || continue
    env HOME="$SANDBOX_HOME" mise trust "$cfg" > /dev/null 2>&1 || true
  done
}

# Drive the top-level entry point. --ci is forced: it stops install.sh from
# running `git pull` (and stashing) against this checkout.
cmd_install_sh() {
  prepare_sandbox
  env \
    HOME="$SANDBOX_HOME" \
    XDG_CONFIG_HOME="${SANDBOX_HOME}/.config" \
    APPDATA="${SANDBOX_HOME}/AppData/Roaming" \
    DOTFILES_DIR="$REPO_DIR" \
    ${DOTFILES_OS_OVERRIDE:+DOTFILES_OS_OVERRIDE="$DOTFILES_OS_OVERRIDE"} \
    bash "${REPO_DIR}/install.sh" --ci "$@"
}

# Full lifecycle on a fresh sandbox, with assertions at each step.
cmd_smoke() {
  local os="${DOTFILES_OS_OVERRIDE:-$(uname -s)}"
  echo "===> smoke: fresh sandbox at $SANDBOX_HOME (os=$os)"
  reset_sandbox

  echo
  echo "===> 1/6 status on an empty home (expect NONE everywhere)"
  cmd_status | tail -n 30

  echo
  echo "===> 2/6 install"
  cmd_install | tail -n 20

  echo
  echo "===> 3/6 verify symlinks resolve into the repo"
  case "${DOTFILES_OS_OVERRIDE:-}" in
    windows)
      assert_link ".gitconfig"
      assert_link "Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
      ;;
    ubuntu | mint | linux)
      assert_link ".zshrc"
      assert_link ".config/starship.toml"
      assert_link ".config/Code/User/extensions.json"
      ;;
    *)
      assert_link ".zshrc"
      assert_link ".gitconfig"
      assert_link ".config/mise/config.toml"
      assert_link ".hammerspoon/init.lua"
      ;;
  esac
  assert_link ".claude/settings.json"

  echo
  echo "===> 4/6 install again (idempotency: no new backups, no errors)"
  cmd_install | tail -n 5
  local backups=0
  [[ -d "${SANDBOX_HOME}/.dotfiles_backup" ]] &&
    backups=$(find "${SANDBOX_HOME}/.dotfiles_backup" -type f | wc -l | tr -d ' ')
  echo "backup files after second install: $backups (expected 0)"
  [[ "$backups" == "0" ]] || { echo "FAIL: re-install created backups" >&2; return 1; }

  echo
  echo "===> 5/6 uninstall"
  cmd_uninstall | tail -n 10

  echo
  echo "===> 6/6 verify removal"
  # Assert on a file this platform actually installs -- asserting ".zshrc" is
  # absent on windows would pass without proving anything.
  case "${DOTFILES_OS_OVERRIDE:-}" in
    windows)
      assert_absent ".gitconfig"
      assert_absent "Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
      ;;
    *)
      assert_absent ".zshrc"
      ;;
  esac
  assert_absent ".claude/settings.json"

  echo
  echo "===> smoke PASSED (os=$os)"
}

# Run the smoke lifecycle once per supported platform.
cmd_matrix() {
  local plat
  for plat in macos ubuntu windows; do
    echo
    echo "############################################################"
    echo "# platform: $plat"
    echo "############################################################"
    DOTFILES_OS_OVERRIDE="$plat" SANDBOX_HOME="${SANDBOX_ROOT}/home-${plat}" \
      "$0" smoke
  done
  echo
  echo "===> matrix PASSED (macos, ubuntu, windows)"
}

cmd_clean() {
  assert_sandbox_safe
  rm -rf "$SANDBOX_ROOT"
  echo "removed $SANDBOX_ROOT"
}

cmd_help() {
  cat << EOF
driver.sh - sandboxed harness for this dotfiles repo

All commands run with HOME=$SANDBOX_HOME (never the real home directory).

Commands:
  status              scripts/dotfiles.sh status
  install             scripts/dotfiles.sh install
  uninstall           scripts/dotfiles.sh uninstall
  doctor              scripts/dotfiles.sh doctor
  install-sh [args]   install.sh (--ci is always added), e.g. install-sh --dry-run
  links               list every symlink in the sandbox home
  smoke               full lifecycle with assertions on a fresh sandbox
  matrix              smoke for macos + ubuntu + windows
  clean               delete $SANDBOX_ROOT
  help                this text

Environment:
  SANDBOX_HOME           sandbox home dir (default $SANDBOX_ROOT/home)
  DOTFILES_OS_OVERRIDE   macos | ubuntu | mint | linux | windows
  DOTFILES_MODE          personal | work (which src/.claude/settings.*.json is linked)
  LOG_LEVEL              DEBUG for verbose output
EOF
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    status)     cmd_status "$@" ;;
    install)    cmd_install "$@" ;;
    uninstall)  cmd_uninstall "$@" ;;
    doctor)     cmd_doctor "$@" ;;
    install-sh) cmd_install_sh "$@" ;;
    links)      list_links ;;
    smoke)      cmd_smoke ;;
    matrix)     cmd_matrix ;;
    clean)      cmd_clean ;;
    help | -h | --help) cmd_help ;;
    *)
      echo "Unknown command: $cmd" >&2
      cmd_help >&2
      exit 1
      ;;
  esac
}

main "$@"
