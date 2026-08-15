#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# symlink.sh - Symlink management for dotfiles
# ------------------------------------------------------------------------------

# Include guard to prevent multiple sourcing
if [[ -n "${_SYMLINK_SH_LOADED:-}" ]]; then
  return 0
fi
readonly _SYMLINK_SH_LOADED=1

# Backup root and per-run backup directory (can be overridden)
BACKUP_ROOT="${BACKUP_ROOT:-${HOME}/.dotfiles_backup}"
BACKUP_DIR="${BACKUP_DIR:-${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)}"

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
    # ln の失敗を検査せずに成功ログを出すと、実際には作られていない symlink を
    # 「作成済み」と報告してしまう。呼び出し元は if で受けるため set -e は効かない。
    if ! ln -s "$src" "$dest"; then
      log_error "Failed to create symlink: $dest -> $src"
      return 1
    fi
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

# Find the most recent backup of a given destination path.
# バックアップは実行ごとの timestamp ディレクトリ配下に絶対パスで積まれるため、
# 復元時は「今回の BACKUP_DIR」ではなく全 timestamp を新しい順に探す必要がある。
# Usage: find_latest_backup "/path/to/file" -> prints backup path, or returns 1
find_latest_backup() {
  local dest="$1"

  [[ -d "$BACKUP_ROOT" ]] || return 1

  local candidate
  # ディレクトリ名が YYYYmmdd_HHMMSS なので辞書順の降順 = 新しい順
  while IFS= read -r candidate; do
    if [[ -e "${candidate}${dest}" ]]; then
      echo "${candidate}${dest}"
      return 0
    fi
  done < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort -r)

  return 1
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
    local backup_path
    if backup_path=$(find_latest_backup "$dest"); then
      mv "$backup_path" "$dest"
      log_info "Restored from backup: $backup_path -> $dest"
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
