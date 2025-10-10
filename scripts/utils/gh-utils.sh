#!/usr/bin/env bash

# GitHub CLI Utilities Module
# Reusable bash functions for GitHub CLI operations in the spec framework
# All functions return 0 on success, 1 on error
# Error messages are written to stderr

set -uo pipefail

# Mock gh command for testing
# When GH_MOCK_MODE=1, use environment variables instead of real gh CLI
gh_cmd() {
  if [[ "${GH_MOCK_MODE:-0}" == "1" ]]; then
    # Mock implementation for tests
    local cmd="$1"
    shift

    case "$cmd" in
      "auth")
        if [[ "${GH_MOCK_NOT_INSTALLED:-false}" == "true" ]]; then
          return 127
        fi
        if [[ "${GH_MOCK_AUTH_STATUS:-success}" == "success" ]]; then
          echo "Logged in to github.com as test-user"
          return 0
        else
          return 1
        fi
        ;;
      "pr")
        local subcmd="$1"
        shift
        case "$subcmd" in
          "list")
            if [[ "${GH_MOCK_PR_EXISTS:-false}" == "true" ]]; then
              echo "${GH_MOCK_PR_URL}"
              return 0
            else
              return 0  # Empty list
            fi
            ;;
          "create")
            if [[ "${GH_MOCK_RATE_LIMIT:-false}" == "true" ]]; then
              echo "API rate limit exceeded" >&2
              return 1
            fi
            echo "${GH_MOCK_PR_URL}"
            return 0
            ;;
          "view")
            if [[ "${GH_MOCK_NETWORK_ERROR:-false}" == "true" ]]; then
              echo "network error" >&2
              return 1
            fi
            if [[ "${GH_MOCK_PR_STATUS:-}" == "not_found" ]]; then
              echo "PR not found" >&2
              return 1
            fi
            if [[ "${GH_MOCK_PR_STATUS:-}" =~ ^\{.*\}$ ]]; then
              echo "${GH_MOCK_PR_STATUS}"
              return 0
            fi
            # Check if --json flag is present to determine what to return
            local json_flag=""
            for arg in "$@"; do
              if [[ "$arg" == "--json" ]]; then
                json_flag="$2"
                break
              fi
            done

            if [[ "$json_flag" == "reviewDecision" ]]; then
              echo "{\"reviewDecision\":\"${GH_MOCK_REVIEW_DECISION:-APPROVED}\"}"
            else
              # Default full PR response
              echo "{\"number\":123,\"title\":\"Test PR\",\"state\":\"OPEN\",\"reviewDecision\":\"${GH_MOCK_REVIEW_DECISION:-APPROVED}\"}"
            fi
            return 0
            ;;
          "merge")
            if [[ "${GH_MOCK_MERGE_SUCCESS:-true}" == "true" ]]; then
              echo "Merged PR #${1}"
              return 0
            else
              echo "${GH_MOCK_MERGE_ERROR:-Failed to merge}" >&2
              return 1
            fi
            ;;
        esac
        ;;
    esac
    return 1
  else
    # Real gh CLI command
    command gh "$@"
  fi
}

# Check if GitHub CLI is authenticated
# Returns: 0 if authenticated, 1 otherwise
check_gh_auth() {
  # Check if gh is installed (mock mode check)
  if [[ "${GH_MOCK_NOT_INSTALLED:-false}" == "true" ]]; then
    echo "Error: GitHub CLI (gh) is not installed" >&2
    echo "Please install it from: https://cli.github.com/" >&2
    return 1
  fi

  # Check if gh is installed (real check)
  if [[ "${GH_MOCK_MODE:-0}" != "1" ]] && ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed" >&2
    echo "Please install it from: https://cli.github.com/" >&2
    return 1
  fi

  # Check authentication status
  if ! gh_cmd auth status >/dev/null 2>&1; then
    echo "Error: GitHub CLI is not authenticated" >&2
    echo "Please run: gh auth login" >&2
    return 1
  fi

  return 0
}

# Check if PR exists for a branch
# Args: $1 - branch name (with or without spec/ prefix)
# Returns: 0 if PR exists, 1 if not
pr_exists_for_branch() {
  local branch="$1"

  # Add spec/ prefix if not present
  if [[ ! "$branch" =~ ^spec/ ]]; then
    branch="spec/${branch}"
  fi

  # Query for PRs with this head branch
  local pr_list
  pr_list=$(gh_cmd pr list --head "$branch" --json url --jq '.[0].url' 2>/dev/null)

  if [[ -n "$pr_list" ]]; then
    return 0
  fi

  return 1
}

# Create a GitHub PR
# Args: $1 - feature name, $2 - PR title, $3 - PR body
# Returns: PR URL on stdout, 0 on success, 1 on error
create_pr() {
  local feature_name="$1"
  local title="$2"
  local body="$3"

  # Validate inputs
  if [[ -z "$feature_name" ]]; then
    echo "Error: Feature name required" >&2
    return 1
  fi

  if [[ -z "$title" ]]; then
    echo "Error: Title required" >&2
    return 1
  fi

  if [[ -z "$body" ]]; then
    echo "Error: Body required" >&2
    return 1
  fi

  # Check authentication
  if ! check_gh_auth; then
    return 1
  fi

  # Check if PR already exists
  local branch="spec/${feature_name}"
  if pr_exists_for_branch "$feature_name"; then
    local existing_url
    existing_url=$(gh_cmd pr list --head "$branch" --json url --jq '.[0].url' 2>/dev/null)
    echo "PR already exists: ${existing_url}"
    echo "${existing_url}"
    return 0
  fi

  # Create PR
  local pr_url
  if [[ "${GH_MOCK_RATE_LIMIT:-false}" == "true" ]]; then
    echo "Error: GitHub API rate limit exceeded" >&2
    echo "Please wait a few minutes and try again" >&2
    return 1
  fi

  pr_url=$(gh_cmd pr create --title "$title" --body "$body" 2>&1)

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create PR" >&2
    echo "$pr_url" >&2
    return 1
  fi

  echo "$pr_url"
  return 0
}

# Get PR review decision
# Args: $1 - PR number
# Returns: Review decision (APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED) on stdout
get_pr_review_decision() {
  local pr_number="$1"

  if [[ -z "$pr_number" ]]; then
    echo "Error: PR number required" >&2
    return 1
  fi

  local pr_json
  pr_json=$(gh_cmd pr view "$pr_number" --json reviewDecision 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get PR review decision" >&2
    return 1
  fi

  # Use jq to extract reviewDecision value
  local review_decision
  review_decision=$(echo "$pr_json" | jq -r '.reviewDecision' 2>/dev/null)

  # Handle null (no reviews yet)
  if [[ "$review_decision" == "null" ]] || [[ -z "$review_decision" ]]; then
    echo "REVIEW_REQUIRED"
  else
    echo "$review_decision"
  fi

  return 0
}

# Get full PR status as JSON
# Args: $1 - PR number
# Returns: PR JSON on stdout, 0 on success, 1 on error
get_pr_status() {
  local pr_number="$1"

  if [[ -z "$pr_number" ]]; then
    echo "Error: PR number required" >&2
    return 1
  fi

  local pr_json
  pr_json=$(gh_cmd pr view "$pr_number" --json number,title,state,reviewDecision,mergeable,reviews 2>&1)

  if [[ $? -ne 0 ]]; then
    if [[ "$pr_json" =~ "not found" ]] || [[ "${GH_MOCK_PR_STATUS:-}" == "not_found" ]]; then
      echo "Error: PR #${pr_number} not found" >&2
      return 1
    fi
    if [[ "$pr_json" =~ "network" ]] || [[ "${GH_MOCK_NETWORK_ERROR:-false}" == "true" ]]; then
      echo "Error: Network error while fetching PR status" >&2
      return 1
    fi
    echo "Error: Failed to get PR status" >&2
    echo "$pr_json" >&2
    return 1
  fi

  # Validate JSON
  if ! echo "$pr_json" | jq empty 2>/dev/null; then
    echo "Error: Failed to parse PR JSON response" >&2
    return 1
  fi

  echo "$pr_json"
  return 0
}

# Merge a PR with squash strategy
# Args: $1 - PR number
# Returns: 0 on success, 1 on error
merge_pr() {
  local pr_number="$1"

  if [[ -z "$pr_number" ]]; then
    echo "Error: PR number required" >&2
    return 1
  fi

  # Check if PR is approved
  local review_decision
  review_decision=$(get_pr_review_decision "$pr_number" 2>/dev/null)
  local review_status=$?

  if [[ $review_status -ne 0 ]] || [[ "$review_decision" != "APPROVED" ]]; then
    echo "Error: PR must be approved before merging" >&2
    if [[ -n "$review_decision" ]]; then
      echo "Current review status: ${review_decision}" >&2
    fi
    return 1
  fi

  # Attempt to merge
  local merge_result
  merge_result=$(gh_cmd pr merge "$pr_number" --squash --delete-branch 2>&1)
  local merge_status=$?

  if [[ $merge_status -ne 0 ]]; then
    if [[ "$merge_result" =~ "conflicts" ]] || [[ "${GH_MOCK_MERGE_ERROR:-}" =~ "conflicts" ]]; then
      echo "Error: PR has merge conflicts" >&2
      echo "Please resolve conflicts before merging" >&2
    else
      echo "Error: Failed to merge PR" >&2
      echo "$merge_result" >&2
    fi
    return 1
  fi

  echo "PR #${pr_number} merged successfully"
  return 0
}
