#!/usr/bin/env bats

# Unit tests for gh-utils.sh
# Following TDD: Write tests first (Red), implement (Green), refactor (Refactor)
# Mock gh CLI responses to avoid hitting real GitHub API

setup() {
  # Create temporary test directory
  export TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"

  # Initialize git repo
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"

  # Create initial commit on main
  echo "initial" > README.md
  git add README.md
  git commit -q -m "Initial commit"
  git branch -M main

  # Source the gh-utils module
  source "${BATS_TEST_DIRNAME}/gh-utils.sh"

  # Mock gh CLI command for tests
  export GH_MOCK_MODE=1
  export GH_MOCK_AUTH_STATUS="success"
  export GH_MOCK_PR_URL="https://github.com/test/repo/pull/123"
  export GH_MOCK_PR_NUMBER="123"
  export GH_MOCK_REVIEW_DECISION="APPROVED"
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
  unset GH_MOCK_MODE
  unset GH_MOCK_AUTH_STATUS
  unset GH_MOCK_PR_URL
  unset GH_MOCK_PR_NUMBER
  unset GH_MOCK_REVIEW_DECISION
}

# Test: check_gh_auth()
@test "check_gh_auth returns 0 when authenticated" {
  export GH_MOCK_AUTH_STATUS="success"
  run check_gh_auth
  [ "$status" -eq 0 ]
}

@test "check_gh_auth returns 1 when not authenticated" {
  export GH_MOCK_AUTH_STATUS="failed"
  run check_gh_auth
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not authenticated" ]]
}

@test "check_gh_auth provides helpful error message" {
  export GH_MOCK_AUTH_STATUS="failed"
  run check_gh_auth
  [ "$status" -eq 1 ]
  [[ "$output" =~ "gh auth login" ]]
}

# Test: pr_exists_for_branch()
@test "pr_exists_for_branch returns 0 when PR exists" {
  export GH_MOCK_PR_EXISTS="true"
  run pr_exists_for_branch "spec/test-feature"
  [ "$status" -eq 0 ]
}

@test "pr_exists_for_branch returns 1 when no PR exists" {
  export GH_MOCK_PR_EXISTS="false"
  run pr_exists_for_branch "spec/test-feature"
  [ "$status" -eq 1 ]
}

@test "pr_exists_for_branch handles branch without spec/ prefix" {
  export GH_MOCK_PR_EXISTS="true"
  run pr_exists_for_branch "test-feature"
  [ "$status" -eq 0 ]
}

# Test: create_pr()
@test "create_pr creates PR and returns URL" {
  run create_pr "test-feature" "Test PR Title" "Test PR Body"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "https://github.com/test/repo/pull/123" ]]
}

@test "create_pr fails when not authenticated" {
  export GH_MOCK_AUTH_STATUS="failed"
  run create_pr "test-feature" "Test PR Title" "Test PR Body"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not authenticated" ]]
}

@test "create_pr returns existing PR URL if already exists" {
  export GH_MOCK_PR_EXISTS="true"
  export GH_MOCK_PR_URL="https://github.com/test/repo/pull/456"
  run create_pr "test-feature" "Test PR Title" "Test PR Body"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "https://github.com/test/repo/pull/456" ]]
  [[ "$output" =~ "already exists" ]]
}

@test "create_pr requires feature name" {
  run create_pr "" "Test PR Title" "Test PR Body"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Feature name required" ]]
}

@test "create_pr requires title" {
  run create_pr "test-feature" "" "Test PR Body"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Title required" ]]
}

@test "create_pr requires body" {
  run create_pr "test-feature" "Test PR Title" ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Body required" ]]
}

# Test: get_pr_review_decision()
@test "get_pr_review_decision returns APPROVED status" {
  export GH_MOCK_REVIEW_DECISION="APPROVED"
  run get_pr_review_decision "123"
  [ "$status" -eq 0 ]
  [ "$output" = "APPROVED" ]
}

@test "get_pr_review_decision returns CHANGES_REQUESTED status" {
  export GH_MOCK_REVIEW_DECISION="CHANGES_REQUESTED"
  run get_pr_review_decision "123"
  [ "$status" -eq 0 ]
  [ "$output" = "CHANGES_REQUESTED" ]
}

@test "get_pr_review_decision returns REVIEW_REQUIRED status" {
  export GH_MOCK_REVIEW_DECISION="REVIEW_REQUIRED"
  run get_pr_review_decision "123"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEW_REQUIRED" ]
}

@test "get_pr_review_decision handles null (no reviews)" {
  export GH_MOCK_REVIEW_DECISION="null"
  run get_pr_review_decision "123"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEW_REQUIRED" ]
}

@test "get_pr_review_decision requires PR number" {
  run get_pr_review_decision ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "PR number required" ]]
}

# Test: get_pr_status()
@test "get_pr_status returns JSON with PR details" {
  export GH_MOCK_PR_STATUS='{"number":123,"title":"Test PR","state":"OPEN","reviewDecision":"APPROVED"}'
  run get_pr_status "123"
  [ "$status" -eq 0 ]
  [[ "$output" =~ '"number":123' ]]
  [[ "$output" =~ '"reviewDecision":"APPROVED"' ]]
}

@test "get_pr_status fails when PR not found" {
  export GH_MOCK_PR_STATUS="not_found"
  run get_pr_status "999"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

@test "get_pr_status requires PR number" {
  run get_pr_status ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "PR number required" ]]
}

# Test: merge_pr()
@test "merge_pr merges with squash strategy" {
  export GH_MOCK_MERGE_SUCCESS="true"
  run merge_pr "123"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "merged successfully" ]]
}

@test "merge_pr fails when not mergeable" {
  export GH_MOCK_MERGE_SUCCESS="false"
  export GH_MOCK_MERGE_ERROR="PR has conflicts"
  run merge_pr "123"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "conflicts" ]]
}

@test "merge_pr fails when not approved" {
  export GH_MOCK_REVIEW_DECISION="CHANGES_REQUESTED"
  export GH_MOCK_MERGE_SUCCESS="false"
  run merge_pr "123"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "approved" ]]
}

@test "merge_pr requires PR number" {
  run merge_pr ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "PR number required" ]]
}

# Test: Error handling
@test "handles gh CLI not installed" {
  export GH_MOCK_NOT_INSTALLED="true"
  run check_gh_auth
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not installed" ]]
  [[ "$output" =~ "GitHub CLI" ]]
}

@test "handles rate limiting gracefully" {
  export GH_MOCK_RATE_LIMIT="true"
  run create_pr "test-feature" "Test PR" "Test Body"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "rate limit" ]]
}

@test "handles network errors" {
  export GH_MOCK_NETWORK_ERROR="true"
  run get_pr_status "123"
  [ "$status" -eq 1 ]
  [[ "$output" =~ [Nn]etwork ]]
}

# Test: JSON parsing with jq
@test "parses PR number from JSON response" {
  export GH_MOCK_PR_STATUS='{"number":456,"title":"Test"}'
  result=$(get_pr_status "456" | jq -r '.number')
  [ "$result" = "456" ]
}
