#!/usr/bin/env bats
# E2E Tests for GitHub PR Integration
# Tests the complete workflow: init → create-pr → status → complete

# Setup and teardown
setup() {
  # Resolve framework root - use BATS_TEST_DIRNAME which is set by bats
  export FRAMEWORK_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_FEATURE="test-e2e-$(date +%s)"
  export GH_MOCK_MODE="1"  # Use mock mode for E2E tests to avoid hitting real GitHub
  export GH_MOCK_PR_URL="https://github.com/test-user/test-repo/pull/123"  # Mock PR URL

  # Create temporary test directory
  export TEST_DIR="$(mktemp -d)"
  cd "${TEST_DIR}"

  # Initialize git repo
  git init -b main
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "# Test Repo" > README.md
  git add README.md
  git commit -m "Initial commit"

  # Copy framework files - resolve full path
  local scripts_path
  local commands_path
  scripts_path="$(cd "${FRAMEWORK_ROOT}" && pwd)/scripts"
  commands_path="$(cd "${FRAMEWORK_ROOT}" && pwd)/commands"

  cp -r "${scripts_path}" ./
  cp -r "${commands_path}" ./
  mkdir -p ./specs

  # Commit framework files to keep working directory clean
  git add scripts commands specs
  git commit -m "Add framework files" --quiet

  # Source utilities for testing
  source ./scripts/utils/git-utils.sh
  source ./scripts/utils/gh-utils.sh
}

teardown() {
  # Clean up test directory
  cd /
  rm -rf "${TEST_DIR}"
}

# Helper function to simulate spec init command
run_spec_init() {
  local feature_name="$1"

  # Validate preconditions
  is_on_main_branch || return 1
  check_clean_working_directory || return 1

  # Create spec branch
  create_spec_branch "${feature_name}" || return 1

  # Create spec directory
  mkdir -p "./specs/${feature_name}"

  # Create metadata
  cat > "./specs/${feature_name}/.spec-meta.json" <<EOF
{
  "feature": "${feature_name}",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "phase": "initialization",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "branchName": "spec/${feature_name}"
}
EOF

  # Commit spec files to keep directory clean
  git add "./specs/${feature_name}"
  git commit -m "chore: initialize spec ${feature_name}" --quiet

  return 0
}

# Helper function to simulate spec create-pr command
run_spec_create_pr() {
  local feature_name="$1"

  # Verify spec exists
  [ -f "./specs/${feature_name}/.spec-meta.json" ] || return 1

  # Read metadata
  local branch_name
  branch_name="$(jq -r '.branchName' "./specs/${feature_name}/.spec-meta.json")"

  # Verify on correct branch
  [ "$(git branch --show-current)" = "${branch_name#spec/}" ] || \
  [ "$(git branch --show-current)" = "${branch_name}" ] || return 1

  # Check for uncommitted changes
  check_clean_working_directory || return 1

  # Push branch (in real scenario)
  # git push -u origin "${branch_name}"

  # Create PR body
  local pr_body
  pr_body="## Spec Implementation: ${feature_name}

This PR implements the spec for **${feature_name}**.

### Documentation
- Requirements: [requirements.md](./specs/${feature_name}/requirements.md)
- Design: [design.md](./specs/${feature_name}/design.md)
- Tasks: [tasks.md](./specs/${feature_name}/tasks.md)

### Checklist
- [x] All tasks completed
- [x] Tests passing
- [x] Documentation updated

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

  # Create PR using gh-utils
  local pr_url
  pr_url="$(create_pr "${feature_name}" "[Spec] ${feature_name}" "${pr_body}")" || return 1

  # Extract PR number from URL
  local pr_number
  pr_number="$(echo "${pr_url}" | grep -o '[0-9]*$')"

  # Update metadata
  local current_meta
  current_meta="$(cat "./specs/${feature_name}/.spec-meta.json")"

  echo "${current_meta}" | jq \
    --arg prUrl "${pr_url}" \
    --arg prNumber "${pr_number}" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")" \
    '. + {
      prUrl: $prUrl,
      prNumber: ($prNumber | tonumber),
      prStatus: null,
      prCreatedAt: $timestamp,
      prUpdatedAt: $timestamp,
      phase: "in-review"
    }' > "./specs/${feature_name}/.spec-meta.json.tmp"

  mv "./specs/${feature_name}/.spec-meta.json.tmp" "./specs/${feature_name}/.spec-meta.json"

  # Commit metadata update (keep working directory clean for subsequent operations)
  git add "./specs/${feature_name}/.spec-meta.json"
  git commit -m "chore: update spec metadata with PR info" --quiet

  echo "${pr_url}"
  return 0
}

# ========================================
# Happy Path Tests
# ========================================

@test "init creates branch and metadata" {
  run run_spec_init "${TEST_FEATURE}"
  [ "$status" -eq 0 ]

  # Verify branch created
  local current_branch
  current_branch="$(git branch --show-current)"
  [ "${current_branch}" = "spec/${TEST_FEATURE}" ]

  # Verify metadata created
  [ -f "./specs/${TEST_FEATURE}/.spec-meta.json" ]

  # Verify branch name in metadata
  local branch_from_meta
  branch_from_meta="$(jq -r '.branchName' "./specs/${TEST_FEATURE}/.spec-meta.json")"
  [ "${branch_from_meta}" = "spec/${TEST_FEATURE}" ]

  # Verify phase
  local phase
  phase="$(jq -r '.phase' "./specs/${TEST_FEATURE}/.spec-meta.json")"
  [ "${phase}" = "initialization" ]
}

@test "create-pr creates PR and stores URL" {
  # Initialize spec
  run_spec_init "${TEST_FEATURE}"

  # Create a commit (required for PR)
  echo "test implementation" > test.txt
  git add test.txt
  git commit -m "test: add implementation"

  # Create PR (don't use run, execute directly)
  run_spec_create_pr "${TEST_FEATURE}"
  local pr_result=$?
  [ "${pr_result}" -eq 0 ]

  # Verify PR URL stored
  local pr_url
  pr_url="$(jq -r '.prUrl' "./specs/${TEST_FEATURE}/.spec-meta.json")"
  [ -n "${pr_url}" ]
  [[ "${pr_url}" =~ ^https://github.com/.*/pull/[0-9]+$ ]]

  # Verify PR number stored
  local pr_number
  pr_number="$(jq -r '.prNumber' "./specs/${TEST_FEATURE}/.spec-meta.json")"
  [ "${pr_number}" -gt 0 ]

  # Verify phase updated
  local phase
  phase="$(jq -r '.phase' "./specs/${TEST_FEATURE}/.spec-meta.json")"
  [ "${phase}" = "in-review" ]
}

@test "status shows PR information when PR exists" {
  # Initialize spec and create PR
  run_spec_init "${TEST_FEATURE}"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"
  run_spec_create_pr "${TEST_FEATURE}"

  # Get PR number
  local pr_number
  pr_number="$(jq -r '.prNumber' "./specs/${TEST_FEATURE}/.spec-meta.json")"

  # Check review decision
  run get_pr_review_decision "${pr_number}"
  [ "$status" -eq 0 ]

  # Should return a valid review status
  [[ "$output" =~ ^(APPROVED|REVIEW_REQUIRED|CHANGES_REQUESTED)$ ]]
}

# ========================================
# Error Scenario Tests
# ========================================

@test "init fails when not on main branch" {
  # Create and checkout feature branch
  git checkout -b feature-branch

  # Try to init (should fail)
  run run_spec_init "${TEST_FEATURE}"
  [ "$status" -ne 0 ]

  # Spec directory should not be created
  [ ! -d "./specs/${TEST_FEATURE}" ]
}

@test "init fails when working directory is dirty" {
  # Create uncommitted changes
  echo "uncommitted" > dirty.txt
  git add dirty.txt

  # Try to init (should fail)
  run run_spec_init "${TEST_FEATURE}"
  [ "$status" -ne 0 ]

  # Spec directory should not be created
  [ ! -d "./specs/${TEST_FEATURE}" ]
}

@test "create-pr fails when spec doesn't exist" {
  # Try to create PR for non-existent spec
  run run_spec_create_pr "non-existent-spec"
  [ "$status" -ne 0 ]
}

@test "gh auth check detects unauthenticated state" {
  # Set mock to simulate unauthenticated state
  export GH_MOCK_MODE="1"
  export GH_MOCK_AUTH_STATUS="fail"

  run check_gh_auth
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not authenticated" ]] || [[ "$output" =~ "login" ]]

  # Reset mock
  unset GH_MOCK_AUTH_STATUS
}

# ========================================
# Edge Case Tests
# ========================================

@test "branch already exists is handled gracefully" {
  # Create branch manually
  git checkout -b "spec/${TEST_FEATURE}"
  git checkout main

  # Try to init (should fail with clear message)
  run run_spec_init "${TEST_FEATURE}"
  [ "$status" -ne 0 ]
}

@test "feature name validation rejects invalid names" {
  # Test uppercase
  run validate_feature_name "TestFeature"
  [ "$status" -ne 0 ]

  # Test spaces
  run validate_feature_name "test feature"
  [ "$status" -ne 0 ]

  # Test underscores
  run validate_feature_name "test_feature"
  [ "$status" -ne 0 ]

  # Test special characters
  run validate_feature_name "test@feature"
  [ "$status" -ne 0 ]

  # Valid names should pass
  run validate_feature_name "test-feature"
  [ "$status" -eq 0 ]

  run validate_feature_name "test-feature-123"
  [ "$status" -eq 0 ]
}

# ========================================
# Integration Tests
# ========================================

@test "branch cleanup works correctly" {
  # Create test branch
  local test_branch="spec/test-cleanup"
  git checkout -b "${test_branch}"
  git checkout main

  # Verify branch exists
  run branch_exists "${test_branch}"
  [ "$status" -eq 0 ]

  # Delete branch
  run delete_spec_branch "test-cleanup"
  [ "$status" -eq 0 ]

  # Verify branch deleted
  run branch_exists "${test_branch}"
  [ "$status" -ne 0 ]
}

# ========================================
# Metadata Validation Tests
# ========================================

@test "metadata contains all required fields after init" {
  run_spec_init "${TEST_FEATURE}"

  local metadata
  metadata="$(cat "./specs/${TEST_FEATURE}/.spec-meta.json")"

  # Check required fields exist
  echo "${metadata}" | jq -e '.feature' > /dev/null
  echo "${metadata}" | jq -e '.created' > /dev/null
  echo "${metadata}" | jq -e '.phase' > /dev/null
  echo "${metadata}" | jq -e '.lastUpdated' > /dev/null
  echo "${metadata}" | jq -e '.branchName' > /dev/null

  # Verify values
  [ "$(echo "${metadata}" | jq -r '.feature')" = "${TEST_FEATURE}" ]
  [ "$(echo "${metadata}" | jq -r '.phase')" = "initialization" ]
  [ "$(echo "${metadata}" | jq -r '.branchName')" = "spec/${TEST_FEATURE}" ]
}

# ========================================
# Edge Case Tests (High Priority from Review)
# ========================================

@test "handles PR closed externally before completion" {
  # Initialize spec and create PR
  run_spec_init "${TEST_FEATURE}"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"
  run_spec_create_pr "${TEST_FEATURE}"

  # Simulate PR being closed externally by setting mock status
  export GH_MOCK_PR_STATUS="not_found"

  # Try to check review decision - should handle gracefully
  local pr_number
  pr_number="$(jq -r '.prNumber' "./specs/${TEST_FEATURE}/.spec-meta.json")"

  run get_pr_review_decision "${pr_number}"

  # Should fail gracefully, not crash
  [ "$status" -ne 0 ]

  # Reset mock
  unset GH_MOCK_PR_STATUS
}

@test "handles network failures during PR operations" {
  # Initialize spec and create PR
  run_spec_init "${TEST_FEATURE}"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"
  run_spec_create_pr "${TEST_FEATURE}"

  # Simulate network error
  export GH_MOCK_NETWORK_ERROR="true"

  local pr_number
  pr_number="$(jq -r '.prNumber' "./specs/${TEST_FEATURE}/.spec-meta.json")"

  # Try to get PR status - should handle network error gracefully
  run get_pr_status "${pr_number}"

  # Should fail with network error
  [ "$status" -ne 0 ]
  [[ "$output" =~ "network" ]] || [[ "$output" =~ "Network" ]]

  # Reset mock
  unset GH_MOCK_NETWORK_ERROR
}

@test "handles merge conflicts gracefully" {
  # Initialize spec and create PR
  run_spec_init "${TEST_FEATURE}"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"
  run_spec_create_pr "${TEST_FEATURE}"

  # Simulate merge failure due to conflicts
  export GH_MOCK_MERGE_SUCCESS="false"
  export GH_MOCK_MERGE_ERROR="PR has merge conflicts"

  local pr_number
  pr_number="$(jq -r '.prNumber' "./specs/${TEST_FEATURE}/.spec-meta.json")"

  # First set PR to approved
  export GH_MOCK_REVIEW_DECISION="APPROVED"

  # Try to merge - should fail with conflict error
  run merge_pr "${pr_number}"

  # Should fail
  [ "$status" -ne 0 ]
  [[ "$output" =~ "conflicts" ]]

  # Reset mocks
  unset GH_MOCK_MERGE_SUCCESS
  unset GH_MOCK_MERGE_ERROR
  unset GH_MOCK_REVIEW_DECISION
}

# ========================================
# Success Metrics
# ========================================

# This test verifies all tests can run quickly
@test "test suite completes in reasonable time" {
  # This is a meta-test to ensure tests are not too slow
  # Each test should complete in < 5 seconds
  # Full suite should complete in < 2 minutes

  local start_time
  start_time="$(date +%s)"

  # Run a simple operation
  run_spec_init "speed-test-${RANDOM}"

  local end_time
  end_time="$(date +%s)"
  local duration=$((end_time - start_time))

  # Should complete in < 5 seconds
  [ "${duration}" -lt 5 ]
}
