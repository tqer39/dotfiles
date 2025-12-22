#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# symlink.sh - Symlink management for dotfiles
# ------------------------------------------------------------------------------

# Include guard to prevent multiple sourcing
if [[ -n "${_SYMLINK_SH_LOADED:-}" ]]; then
  return 0
fi
_SYMLINK_SH_LOADED=1

# Backup directory (can be overridden)
BACKUP_DIR="${BACKUP_DIR:-${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)}"

# Dry run mode (can be overridden)
DRY_RUN="${DRY_RUN:-false}"

# Create a symlink idempotently
# - If link already points to source: skip (idempotent)
# - If target exists: backup then create link
# - If target doesn't exist: create link
#
# Usage: create_symlink "/path/to/source" "/path/to/destination"
create_symlink() {
  local src="$1"
  local dest="$2"

  # Validate source exists
  if [[ ! -e "$src" ]]; then
    log_error "Source file does not exist: $src"
    return 1
  fi

  # Check if symlink already points to the correct source (idempotent)
  if [[ -L "$dest" ]]; then
    local current_target
    current_target=$(readlink "$dest")
    if [[ "$current_target" == "$src" ]]; then
      log_debug "Symlink already correct: $dest -> $src"
      return 0
    fi
  fi

  # Ensure parent directory exists
  local dest_dir
  dest_dir=$(dirname "$dest")
  if [[ ! -d "$dest_dir" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would create directory: $dest_dir"
    else
      mkdir -p "$dest_dir"
      log_debug "Created directory: $dest_dir"
    fi
  fi

  # Backup existing file or symlink
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would backup: $dest -> $BACKUP_DIR"
    else
      backup_file "$dest"
    fi
  fi

  # Create symlink
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would create symlink: $dest -> $src"
  else
    ln -s "$src" "$dest"
    log_success "Created symlink: $dest -> $src"
  fi

  return 0
}

# Create symlinks for a directory recursively
# Usage: create_symlinks_recursive "/path/to/src/dir" "/path/to/dest/dir"
create_symlinks_recursive() {
  local src_dir="$1"
  local dest_dir="$2"

  if [[ ! -d "$src_dir" ]]; then
    log_error "Source directory does not exist: $src_dir"
    return 1
  fi

  # Find all files in source directory
  while IFS= read -r -d '' file; do
    local relative_path="${file#"$src_dir"/}"
    local dest_file="$dest_dir/$relative_path"
    create_symlink "$file" "$dest_file"
  done < <(find "$src_dir" -type f -print0)
}

# Backup a file to the backup directory
# Usage: backup_file "/path/to/file"
backup_file() {
  local file="$1"
  local backup_path="${BACKUP_DIR}${file}"
  local backup_dir
  backup_dir=$(dirname "$backup_path")

  # Create backup directory if needed
  if [[ ! -d "$backup_dir" ]]; then
    mkdir -p "$backup_dir"
  fi

  # Move file to backup location
  mv "$file" "$backup_path"
  log_warn "Backed up: $file -> $backup_path"
}

# Remove a symlink and optionally restore from backup
# Usage: remove_symlink "/path/to/symlink" [restore_backup]
remove_symlink() {
  local dest="$1"
  local restore_backup="${2:-false}"

  if [[ ! -L "$dest" ]]; then
    log_warn "Not a symlink, skipping: $dest"
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would remove symlink: $dest"
    return 0
  fi

  rm "$dest"
  log_info "Removed symlink: $dest"

  # Restore from backup if requested and backup exists
  if [[ "$restore_backup" == "true" ]]; then
    local backup_path="${BACKUP_DIR}${dest}"
    if [[ -e "$backup_path" ]]; then
      mv "$backup_path" "$dest"
      log_info "Restored from backup: $dest"
    fi
  fi
}

# Check if a path is a valid symlink pointing to expected source
# Usage: is_symlink_valid "/path/to/symlink" "/expected/source"
is_symlink_valid() {
  local dest="$1"
  local expected_src="$2"

  if [[ ! -L "$dest" ]]; then
    return 1
  fi

  local actual_src
  actual_src=$(readlink "$dest")
  [[ "$actual_src" == "$expected_src" ]]
}
