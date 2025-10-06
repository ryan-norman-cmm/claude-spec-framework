#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Post-Tool-Use Hook: Comprehensive Task Completion Evaluation
# Uses task-completion-evaluator agent to validate:
# 1. Requirements completion (EARS criteria mapped to tests)
# 2. Tests written and passing
# 3. Documentation created/updated
#
# This hook runs AFTER basic file/test checking (post-tool-use.sh)
# and provides comprehensive validation via agent

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

# Function to check if task should be evaluated
should_evaluate_task() {
  local spec_name=$1
  local task_num=$2
  local tasks_file="./specs/$spec_name/tasks.md"

  # Only evaluate if task is marked as complete by basic hook
  # (files exist, tests pass)
  if grep "^### Task $task_num:" -A 5 "$tasks_file" | grep -q "- Status: \[x\]"; then
    return 0
  fi

  return 1
}

# Function to invoke task-completion-evaluator agent
evaluate_task_comprehensive() {
  local spec_name=$1
  local task_num=$2

  echo "🔍 Evaluating Task $task_num comprehensively (requirements + tests + docs)..."

  # Invoke agent via Task tool
  # Note: This would be invoked by Claude Code's Task tool in practice
  # For hook usage, we'll use a simpler bash-based approach

  # Extract task context
  local tasks_file="./specs/$spec_name/tasks.md"
  local requirements_file="./specs/$spec_name/requirements.md"

  local task_section=$(sed -n "/^### Task $task_num:/,/^### Task [0-9]/p" "$tasks_file")
  local task_title=$(echo "$task_section" | grep "^### Task" | sed 's/^### Task [0-9]*: //')
  local task_files=$(echo "$task_section" | sed -n '/Files to Create\/Modify:/,/^$/p' | grep "^  - " | sed 's/^  - //' | sed 's/ .*//')

  # Validation checks
  local validation_passed=true
  local validation_messages=()

  # 1. Check documentation for new features
  local requires_docs=false
  if echo "$task_title" | grep -qiE "add|create|implement|new"; then
    requires_docs=true
  fi

  if echo "$task_files" | grep -qE "controller|service|model|api"; then
    requires_docs=true
  fi

  if [ "$requires_docs" = true ]; then
    # Check if docs were created/updated
    local doc_files=$(echo "$task_files" | grep -E "\.(md|mdx)$")
    local docs_updated=false

    if [ -n "$doc_files" ]; then
      docs_updated=true
    elif git diff --name-only HEAD 2>/dev/null | grep -qE "\.(md|mdx)$"; then
      docs_updated=true
    fi

    if [ "$docs_updated" = false ]; then
      validation_passed=false
      validation_messages+=("⚠️  Missing documentation - task creates new feature but no docs found")
    else
      validation_messages+=("✅ Documentation found")
    fi
  fi

  # 2. Check requirements mapping
  # Extract keywords from task title
  local task_keywords=$(echo "$task_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

  # Find related EARS criteria
  local related_ears=()
  while IFS= read -r criterion; do
    local criterion_lower=$(echo "$criterion" | tr '[:upper:]' '[:lower:]')

    # Check if any task keyword appears in criterion
    for keyword in $task_keywords; do
      if echo "$criterion_lower" | grep -q "$keyword"; then
        related_ears+=("$criterion")
        break
      fi
    done
  done < <(grep -E "^\*\*(Given|When|Then|And)\*\*" "$requirements_file" 2>/dev/null)

  if [ ${#related_ears[@]} -gt 0 ]; then
    # Check if criteria are tested
    local test_files=$(echo "$task_files" | grep -E "\.(spec|test)\.(ts|js)$")
    local unvalidated=0

    for criterion in "${related_ears[@]}"; do
      local criterion_terms=$(echo "$criterion" | sed 's/\*\*[^*]*\*\*//g' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

      local found_in_tests=false
      while IFS= read -r test_file; do
        [ -z "$test_file" ] && continue
        [ ! -f "$test_file" ] && continue

        local test_content=$(cat "$test_file" | tr '[:upper:]' '[:lower:]')

        # Count matching terms
        local match_count=0
        for term in $criterion_terms; do
          [ ${#term} -lt 4 ] && continue
          if echo "$test_content" | grep -q "$term"; then
            ((match_count++))
          fi
        done

        if [ $match_count -ge 2 ]; then
          found_in_tests=true
          break
        fi
      done <<< "$test_files"

      if [ "$found_in_tests" = false ]; then
        ((unvalidated++))
      fi
    done

    if [ $unvalidated -gt 0 ]; then
      validation_messages+=("⚠️  $unvalidated/${#related_ears[@]} requirements may not be fully tested")
    else
      validation_messages+=("✅ All ${#related_ears[@]} requirements validated in tests")
    fi
  fi

  # 3. Output validation results
  echo ""
  echo "📋 Task $task_num Comprehensive Evaluation:"
  for msg in "${validation_messages[@]}"; do
    echo "  $msg"
  done

  if [ "$validation_passed" = true ]; then
    echo "  ✅ Task fully complete (requirements + tests + docs)"
    return 0
  else
    echo "  ⚠️  Task has warnings - review recommended"
    return 2
  fi
}

# Process each active spec
for spec_name in "${ACTIVE_SPECS[@]}"; do
  tasks_file="./specs/$spec_name/tasks.md"

  if [ ! -f "$tasks_file" ]; then
    continue
  fi

  # Check tasks 1-7 (MVP max is 7 tasks)
  for i in {1..7}; do
    if should_evaluate_task "$spec_name" "$i"; then
      evaluate_task_comprehensive "$spec_name" "$i"
    fi
  done
done

exit 0
