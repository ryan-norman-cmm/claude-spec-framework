#!/usr/bin/env bash
# E2E Test Environment Teardown
# Cleans up test environment and removes test branches

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
export TEST_FEATURE="${TEST_FEATURE:-}"
export TEST_REPO_DIR="${TEST_REPO_DIR:-}"
export CLEANUP_REMOTE="${CLEANUP_REMOTE:-true}"

echo -e "${YELLOW}Tearing down E2E test environment...${NC}"

# Clean up test repository
cleanup_test_repo() {
  if [ -n "${TEST_REPO_DIR}" ] && [ -d "${TEST_REPO_DIR}" ]; then
    echo -e "\n${YELLOW}Removing test repository: ${TEST_REPO_DIR}${NC}"

    # Save current directory
    local current_dir
    current_dir="$(pwd)"

    # Move out of test repo if we're in it
    if [[ "$current_dir" == "${TEST_REPO_DIR}"* ]]; then
      cd /
    fi

    # Remove test repo
    rm -rf "${TEST_REPO_DIR}"
    echo -e "${GREEN}✓ Test repository removed${NC}"
  else
    echo -e "${YELLOW}! No test repository to clean up${NC}"
  fi
}

# Clean up remote branches (if test was using real GitHub)
cleanup_remote_branches() {
  if [ "${CLEANUP_REMOTE}" != "true" ]; then
    echo -e "\n${YELLOW}Skipping remote branch cleanup${NC}"
    return 0
  fi

  if [ -z "${TEST_FEATURE}" ]; then
    echo -e "\n${YELLOW}! No TEST_FEATURE set, skipping remote cleanup${NC}"
    return 0
  fi

  echo -e "\n${YELLOW}Cleaning up remote branches...${NC}"

  local branch_name="spec/${TEST_FEATURE}"

  # Check if we have a remote (only for real GitHub tests)
  if command -v git &> /dev/null && [ -d "${TEST_REPO_DIR}/.git" 2>/dev/null ]; then
    cd "${TEST_REPO_DIR}" 2>/dev/null || return 0

    # Get remote URL if it exists
    local remote_url
    remote_url="$(git remote get-url origin 2>/dev/null || true)"

    if [ -n "${remote_url}" ]; then
      echo "  Attempting to delete remote branch: ${branch_name}"

      # Try to delete remote branch (ignore errors if it doesn't exist)
      if git push origin --delete "${branch_name}" 2>/dev/null; then
        echo -e "${GREEN}✓ Remote branch deleted: ${branch_name}${NC}"
      else
        echo -e "${YELLOW}! Remote branch not found or already deleted: ${branch_name}${NC}"
      fi
    else
      echo -e "${YELLOW}! No remote configured, skipping remote cleanup${NC}"
    fi
  fi
}

# Clean up test PRs (close but don't delete)
cleanup_test_prs() {
  if [ "${CLEANUP_REMOTE}" != "true" ]; then
    return 0
  fi

  if [ -z "${TEST_FEATURE}" ]; then
    return 0
  fi

  echo -e "\n${YELLOW}Cleaning up test PRs...${NC}"

  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}! GitHub CLI not available, skipping PR cleanup${NC}"
    return 0
  fi

  # Check if we're in a GitHub repo
  if [ -d "${TEST_REPO_DIR}/.git" ] && cd "${TEST_REPO_DIR}" 2>/dev/null; then
    local branch_name="spec/${TEST_FEATURE}"

    # Find PRs for this branch
    local pr_numbers
    pr_numbers="$(gh pr list --head "${branch_name}" --json number --jq '.[].number' 2>/dev/null || true)"

    if [ -n "${pr_numbers}" ]; then
      while IFS= read -r pr_number; do
        echo "  Closing PR #${pr_number}"
        if gh pr close "${pr_number}" 2>/dev/null; then
          echo -e "${GREEN}✓ PR #${pr_number} closed${NC}"
        else
          echo -e "${YELLOW}! Failed to close PR #${pr_number}${NC}"
        fi
      done <<< "${pr_numbers}"
    else
      echo -e "${YELLOW}! No test PRs found for ${branch_name}${NC}"
    fi
  fi
}

# Reset git state (checkout main, delete local test branches)
reset_git_state() {
  if [ -d "${TEST_REPO_DIR}/.git" ]; then
    echo -e "\n${YELLOW}Resetting git state...${NC}"

    cd "${TEST_REPO_DIR}" 2>/dev/null || return 0

    # Checkout main to allow branch deletion
    if git rev-parse --verify main &>/dev/null; then
      git checkout main 2>/dev/null || true
    fi

    # Delete local test branch if exists
    if [ -n "${TEST_FEATURE}" ]; then
      local branch_name="spec/${TEST_FEATURE}"
      if git rev-parse --verify "${branch_name}" &>/dev/null; then
        echo "  Deleting local branch: ${branch_name}"
        git branch -D "${branch_name}" 2>/dev/null || true
        echo -e "${GREEN}✓ Local branch deleted${NC}"
      fi
    fi
  fi
}

# Main teardown flow
main() {
  local cleanup_level="${1:-full}"

  case "${cleanup_level}" in
    full)
      reset_git_state
      cleanup_test_prs
      cleanup_remote_branches
      cleanup_test_repo
      ;;
    local-only)
      reset_git_state
      cleanup_test_repo
      ;;
    minimal)
      cleanup_test_repo
      ;;
    *)
      echo -e "${RED}Error: Unknown cleanup level: ${cleanup_level}${NC}"
      echo "Usage: $0 [full|local-only|minimal]"
      exit 1
      ;;
  esac

  echo -e "\n${GREEN}✓ E2E test environment cleaned up!${NC}"
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
