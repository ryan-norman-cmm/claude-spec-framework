#!/usr/bin/env bash

# Git Utilities Module
# Reusable bash functions for git operations in the spec framework
# All functions return 0 on success, 1 on error
# Error messages are written to stderr

set -uo pipefail

# Check if working directory is clean (no uncommitted changes)
# Returns: 0 if clean, 1 if dirty
check_clean_working_directory() {
  if [[ -n $(git status --porcelain) ]]; then
    echo "Error: Working directory must be clean (no uncommitted changes)" >&2
    echo "Please commit or stash your changes before proceeding" >&2
    return 1
  fi
  return 0
}

# Get current branch name
# Returns: Branch name on stdout, 1 if detached HEAD
check_current_branch() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -z "$branch" ]]; then
    echo "Error: Repository is in detached HEAD state" >&2
    return 1
  fi

  echo "$branch"
  return 0
}

# Check if currently on main branch (main or master)
# Returns: 0 if on main/master, 1 otherwise
is_on_main_branch() {
  local current_branch
  current_branch=$(check_current_branch) || return 1

  if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
    return 0
  fi

  return 1
}

# Validate feature name format
# Args: $1 - feature name
# Returns: 0 if valid, 1 if invalid
validate_feature_name() {
  local feature_name="$1"

  if [[ -z "$feature_name" ]]; then
    echo "Error: Feature name cannot be empty" >&2
    return 1
  fi

  # Must be lowercase with hyphens only (no underscores, spaces, uppercase)
  if [[ ! "$feature_name" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Invalid feature name. Must be lowercase with hyphens only" >&2
    echo "Use only: a-z, 0-9, and hyphens" >&2
    return 1
  fi

  return 0
}

# Create spec branch and check it out
# Args: $1 - feature name (will be prefixed with spec/)
# Returns: 0 on success, 1 on error
create_spec_branch() {
  local feature_name="$1"
  local branch_name="spec/${feature_name}"

  # Validate feature name
  validate_feature_name "$feature_name" || return 1

  # Check working directory is clean
  check_clean_working_directory || return 1

  # Check if branch already exists
  if branch_exists "$branch_name"; then
    echo "Error: Branch '$branch_name' already exists" >&2
    echo "Use 'git checkout $branch_name' to switch to it" >&2
    return 1
  fi

  # Create and checkout branch
  git checkout -b "$branch_name" 2>&1 || {
    echo "Error: Failed to create branch '$branch_name'" >&2
    return 1
  }

  return 0
}

# Delete spec branch (local and remote)
# Args: $1 - feature name (will be prefixed with spec/)
# Returns: 0 on success, 1 on error
delete_spec_branch() {
  local feature_name="$1"
  local branch_name="spec/${feature_name}"

  # Check if branch exists
  if ! branch_exists "$branch_name"; then
    echo "Error: Branch '$branch_name' does not exist" >&2
    return 1
  fi

  # Check if currently on the branch
  local current_branch
  current_branch=$(check_current_branch) || return 1

  if [[ "$current_branch" == "$branch_name" ]]; then
    echo "Error: Cannot delete branch '$branch_name' - currently on that branch" >&2
    echo "Please checkout to another branch first (e.g., 'git checkout main')" >&2
    return 1
  fi

  # Delete local branch
  git branch -D "$branch_name" 2>&1 || {
    echo "Error: Failed to delete local branch '$branch_name'" >&2
    return 1
  }

  # Attempt to delete remote branch (fail gracefully if doesn't exist)
  git push origin --delete "$branch_name" 2>/dev/null || true

  return 0
}

# Check if branch exists (local or remote)
# Args: $1 - branch name (can be full or partial, e.g., "test-feature" or "spec/test-feature")
# Returns: 0 if exists, 1 if not
branch_exists() {
  local branch_name="$1"

  # Try exact match first
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    return 0
  fi

  # Try with spec/ prefix if not already prefixed
  if [[ ! "$branch_name" =~ ^spec/ ]]; then
    if git show-ref --verify --quiet "refs/heads/spec/${branch_name}"; then
      return 0
    fi
  fi

  return 1
}
