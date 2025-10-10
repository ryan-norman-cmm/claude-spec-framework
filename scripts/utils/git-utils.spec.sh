#!/usr/bin/env bats

# Unit tests for git-utils.sh
# Following TDD: Write tests first (Red), implement (Green), refactor (Refactor)

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

  # Source the git-utils module
  source "${BATS_TEST_DIRNAME}/git-utils.sh"
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

# Test: check_clean_working_directory()
@test "check_clean_working_directory returns 0 when clean" {
  run check_clean_working_directory
  [ "$status" -eq 0 ]
}

@test "check_clean_working_directory returns 1 when dirty (untracked)" {
  echo "new file" > untracked.txt
  run check_clean_working_directory
  [ "$status" -eq 1 ]
}

@test "check_clean_working_directory returns 1 when dirty (modified)" {
  echo "modified" >> README.md
  run check_clean_working_directory
  [ "$status" -eq 1 ]
}

@test "check_clean_working_directory returns 1 when dirty (staged)" {
  echo "staged" > staged.txt
  git add staged.txt
  run check_clean_working_directory
  [ "$status" -eq 1 ]
}

# Test: check_current_branch()
@test "check_current_branch returns current branch name" {
  run check_current_branch
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "check_current_branch returns branch name on feature branch" {
  git checkout -b feature/test
  run check_current_branch
  [ "$status" -eq 0 ]
  [ "$output" = "feature/test" ]
}

# Test: is_on_main_branch()
@test "is_on_main_branch returns 0 when on main" {
  run is_on_main_branch
  [ "$status" -eq 0 ]
}

@test "is_on_main_branch returns 1 when on feature branch" {
  git checkout -b feature/test
  run is_on_main_branch
  [ "$status" -eq 1 ]
}

@test "is_on_main_branch returns 0 when on master (alternate main)" {
  git branch -m main master
  run is_on_main_branch
  [ "$status" -eq 0 ]
}

# Test: create_spec_branch()
@test "create_spec_branch creates and checks out branch" {
  run create_spec_branch "test-feature"
  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = "spec/test-feature" ]
}

@test "create_spec_branch validates branch name (lowercase only)" {
  run create_spec_branch "TestFeature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "lowercase" ]]
}

@test "create_spec_branch validates branch name (no underscores)" {
  run create_spec_branch "test_feature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "hyphens" ]]
}

@test "create_spec_branch fails when branch already exists" {
  git checkout -b spec/test-feature
  git checkout main
  run create_spec_branch "test-feature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "already exists" ]]
}

@test "create_spec_branch fails when working directory is dirty" {
  echo "dirty" > dirty.txt
  run create_spec_branch "test-feature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "clean" ]]
}

# Test: delete_spec_branch()
@test "delete_spec_branch removes local branch" {
  git checkout -b spec/test-feature
  git checkout main
  run delete_spec_branch "test-feature"
  [ "$status" -eq 0 ]
  ! git show-ref --verify --quiet refs/heads/spec/test-feature
}

@test "delete_spec_branch fails when branch doesn't exist" {
  run delete_spec_branch "nonexistent"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "delete_spec_branch fails when currently on the branch" {
  git checkout -b spec/test-feature
  run delete_spec_branch "test-feature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "currently on" ]]
}

@test "delete_spec_branch attempts to delete remote branch" {
  # Create local branch
  git checkout -b spec/test-feature
  git checkout main

  # Mock remote (this will fail gracefully if no remote)
  run delete_spec_branch "test-feature"
  [ "$status" -eq 0 ]
}

# Test: branch_exists()
@test "branch_exists returns 0 when branch exists" {
  git checkout -b spec/test-feature
  git checkout main
  run branch_exists "spec/test-feature"
  [ "$status" -eq 0 ]
}

@test "branch_exists returns 1 when branch doesn't exist" {
  run branch_exists "spec/nonexistent"
  [ "$status" -eq 1 ]
}

@test "branch_exists works with partial name" {
  git checkout -b spec/test-feature
  git checkout main
  run branch_exists "test-feature"
  [ "$status" -eq 0 ]
}

# Test: Edge cases
@test "handles detached HEAD state gracefully" {
  git checkout --detach HEAD
  run check_current_branch
  [ "$status" -eq 1 ]
  [[ "$output" =~ "detached" ]]
}

@test "validates feature name format" {
  run create_spec_branch "test feature"
  [ "$status" -eq 1 ]
  [[ "$output" =~ [Ii]nvalid ]]
}

@test "validates feature name is not empty" {
  run create_spec_branch ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "empty" ]]
}
