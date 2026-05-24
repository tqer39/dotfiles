#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# skills.sh - Skill discovery utilities
# ------------------------------------------------------------------------------

# Include guard to prevent multiple sourcing
if [[ -n "${_SKILLS_SH_LOADED:-}" ]]; then
  return 0
fi
readonly _SKILLS_SH_LOADED=1

# List Claude Code skill directories managed by this repository.
list_claude_skill_dirs() {
  local skill_root="${DOTFILES_DIR}/.claude/skills"

  if [[ -d "$skill_root" ]]; then
    find "$skill_root" -mindepth 2 -maxdepth 2 -name SKILL.md -print |
      while IFS= read -r skill_file; do
        dirname "$skill_file"
      done
  fi

  find "${DOTFILES_DIR}/src" -path "*/.claude/skills/*/SKILL.md" -print |
    while IFS= read -r skill_file; do
      dirname "$skill_file"
    done
}
