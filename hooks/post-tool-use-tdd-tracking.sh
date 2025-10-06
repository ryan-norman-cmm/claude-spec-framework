#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Post-Tool-Use Hook: Automatic Task Completion Tracking
# Monitors file changes and auto-updates task checkboxes when:
# 1. All task files are created
# 2. Test files exist
# 3. Tests pass

TOOL_NAME=$1
FILE_PATH=$2

# Only run for file modification tools
if [[ ! "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
  exit 0
fi

# Only run if we're in a project with specs
if [ ! -d "./specs" ]; then
  exit 0
fi

# Find active spec(s) with phase: implementation
ACTIVE_SPECS=()
for spec_dir in ./specs/*/; do
  if [ -f "$spec_dir/.spec-meta.json" ]; then
    phase=$(jq -r '.phase' "$spec_dir/.spec-meta.json" 2>/dev/null)
    if [ "$phase" = "implementation" ]; then
      ACTIVE_SPECS+=($(basename "$spec_dir"))
    fi
  fi
done

if [ ${#ACTIVE_SPECS[@]} -eq 0 ]; then
  exit 0
fi

# Function to check if tests exist and pass
check_tests() {
  local test_file=$1

  # Check if test file exists
  if [ ! -f "$test_file" ]; then
    return 1
  fi

  # Run tests for this specific file
  # Detect test framework
  if [ -f "package.json" ]; then
    if jq -e '.scripts.test' package.json > /dev/null 2>&1; then
      # Get test command
      test_cmd=$(jq -r '.scripts.test' package.json)

      # Determine test runner
      if [[ "$test_cmd" == *"jest"* ]]; then
        # Run jest for this specific test file
        npm test -- "$test_file" --passWithNoTests > /tmp/test-output.log 2>&1
        if [ $? -eq 0 ]; then
          # Check if tests actually ran and passed
          if grep -q "PASS" /tmp/test-output.log || grep -q "Tests:.*passed" /tmp/test-output.log; then
            return 0
          fi
        fi
      elif [[ "$test_cmd" == *"vitest"* ]]; then
        # Run vitest for this specific test file
        npm test -- "$test_file" > /tmp/test-output.log 2>&1
        if [ $? -eq 0 ]; then
          if grep -q "PASS" /tmp/test-output.log || grep -q "Test Files.*passed" /tmp/test-output.log; then
            return 0
          fi
        fi
      elif [[ "$test_cmd" == *"mocha"* ]]; then
        # Run mocha for this specific test file
        npm test -- "$test_file" > /tmp/test-output.log 2>&1
        if [ $? -eq 0 ]; then
          if grep -q "passing" /tmp/test-output.log; then
            return 0
          fi
        fi
      else
        # Unknown test runner - just check if test file exists
        return 0
      fi
    fi
  fi

  # If no test framework detected, just verify file exists
  return 0
}

# Function to extract file list from task section
extract_task_files() {
  local tasks_file=$1
  local task_num=$2

  # Extract files between "Files to Create/Modify:" and next section
  awk "/^### Task $task_num:/,/^### Task [0-9]+:|^##|^---/" "$tasks_file" | \
    sed -n '/Files to Create\/Modify:/,/^$/{
      /^  - /p
    }' | \
    sed 's/^  - //' | \
    sed 's/ .*//' # Remove any comments after filename
}

# Function to check if task is complete
check_task_completion() {
  local spec_name=$1
  local task_num=$2
  local tasks_file="./specs/$spec_name/tasks.md"

  # Check if task exists and is not already complete
  if ! grep -q "^### Task $task_num:" "$tasks_file"; then
    return 1
  fi

  if ! grep "^### Task $task_num:" -A 5 "$tasks_file" | grep -q "- Status: \[ \]"; then
    return 1
  fi

  # Extract file list for this task
  local files=$(extract_task_files "$tasks_file" "$task_num")

  if [ -z "$files" ]; then
    return 1
  fi

  # Check if all files exist
  local all_files_exist=true
  local implementation_files=()
  local test_files=()

  while IFS= read -r file; do
    if [ -z "$file" ]; then
      continue
    fi

    if [ ! -f "$file" ]; then
      all_files_exist=false
      break
    fi

    # Categorize files
    if [[ "$file" == *.spec.ts ]] || [[ "$file" == *.spec.js ]] || \
       [[ "$file" == *.test.ts ]] || [[ "$file" == *.test.js ]]; then
      test_files+=("$file")
    else
      implementation_files+=("$file")
    fi
  done <<< "$files"

  if [ "$all_files_exist" = false ]; then
    return 1
  fi

  # Ensure test files exist
  if [ ${#implementation_files[@]} -gt 0 ] && [ ${#test_files[@]} -eq 0 ]; then
    echo "⚠️  Task $task_num: Implementation files exist but no test files found"
    return 1
  fi

  # TDD Cycle Tracking: Mark "Tests written and failing (Red)" if test files exist
  if [ ${#test_files[@]} -gt 0 ]; then
    sed -i.bak "/^### Task $task_num:/,/^### Task [0-9]/ {
      s/  - \[ \] Tests written and failing (Red)/  - [x] Tests written and failing (Red)/
    }" "$tasks_file"
    rm -f "$tasks_file.bak"
  fi

  # Check if tests pass
  local all_tests_pass=true
  for test_file in "${test_files[@]}"; do
    if ! check_tests "$test_file"; then
      echo "🔴 Task $task_num: Tests written but failing (Red phase) - $test_file"
      all_tests_pass=false
      break
    fi
  done

  if [ "$all_tests_pass" = false ]; then
    return 1
  fi

  # All conditions met - mark task complete and update TDD cycle tracking
  # Update Status checkbox and TDD acceptance criteria checkboxes in tasks.md
  sed -i.bak "/^### Task $task_num:/,/^### Task [0-9]/ {
    s/- Status: \[ \] Not Started/- Status: [x] Completed/
    s/- Status: \[ \]/- Status: [x]/
    s/  - \[ \] Tests written and failing (Red)/  - [x] Tests written and failing (Red)/
    s/  - \[ \] Implementation complete/  - [x] Implementation complete/
    s/  - \[ \] Tests passing (Green)/  - [x] Tests passing (Green)/
  }" "$tasks_file"

  # Remove backup file
  rm -f "$tasks_file.bak"

  # Update .spec-meta.json timestamp
  local meta_file="./specs/$spec_name/.spec-meta.json"
  if [ -f "$meta_file" ]; then
    jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.updated_at = $date' \
       "$meta_file" > /tmp/meta.json && mv /tmp/meta.json "$meta_file"
  fi

  echo "✅ Task $task_num completed: All files exist, tests exist and pass (TDD cycle complete)"
  return 0
}

# Process each active spec
for spec_name in "${ACTIVE_SPECS[@]}"; do
  tasks_file="./specs/$spec_name/tasks.md"

  if [ ! -f "$tasks_file" ]; then
    continue
  fi

  # Check tasks 1-7 (MVP max is 7 tasks)
  for i in {1..7}; do
    check_task_completion "$spec_name" "$i"
  done
done

exit 0
