---
allowed-tools: Bash(test:*), Bash(jq:*), Bash(grep:*), Bash(basename:*), Bash(source:*)
description: Show spec status and progress
argument-hint: [feature-name]
---

Spec status: !`bash -c '
FEATURE="$1"
if [ -n "$FEATURE" ]; then
  if [ -f "./specs/$FEATURE/.spec-meta.json" ]; then
    echo "📋 Spec: $FEATURE"
    echo ""
    jq -r "\"Phase: \(.phase)\nBranch: \(.branchName // \"N/A\")\nCreated: \(.created)\nUpdated: \(.lastUpdated)\"" "./specs/$FEATURE/.spec-meta.json"
    if [ -f "./specs/$FEATURE/tasks.md" ]; then
      total=$(grep -c "^## Task" "./specs/$FEATURE/tasks.md" 2>/dev/null || echo 0)
      completed=$(grep -c "^\*\*Status\*\*: \[x\] Completed" "./specs/$FEATURE/tasks.md" 2>/dev/null || echo 0)
      echo "Tasks: $completed/$total completed"
    fi

    # PR Status (NEW)
    pr_url=$(jq -r ".prUrl // empty" "./specs/$FEATURE/.spec-meta.json")
    if [ -n "$pr_url" ]; then
      echo ""
      echo "PR Status:"
      echo "  URL: $pr_url"

      # Source gh-utils to check PR status
      source ./scripts/utils/gh-utils.sh 2>/dev/null || true
      if command -v get_pr_review_decision >/dev/null 2>&1; then
        pr_number=$(jq -r ".prNumber // empty" "./specs/$FEATURE/.spec-meta.json")
        if [ -n "$pr_number" ]; then
          review_status=$(get_pr_review_decision "$pr_number" 2>/dev/null || echo "UNKNOWN")
          case "$review_status" in
            APPROVED)
              echo "  Status: Approved ✓"
              echo ""
              echo "Next action: Run /spec:complete to merge and finish"
              ;;
            CHANGES_REQUESTED)
              echo "  Status: Changes Requested ⚠"
              echo ""
              echo "Next action: Address review comments and push changes"
              ;;
            REVIEW_REQUIRED)
              echo "  Status: Review Required ⏳"
              echo ""
              echo "Next action: Wait for PR approval"
              ;;
            *)
              echo "  Status: $review_status"
              ;;
          esac
        fi
      fi
    else
      echo ""
      echo "Next action: Run /spec:create-pr to create pull request"
    fi
  else
    echo "❌ Spec not found: $FEATURE"
    echo "Initialize with: /spec:init $FEATURE"
  fi
else
  echo "📋 All Specs:"
  echo ""
  if [ -d "./specs" ]; then
    for spec in ./specs/*/; do
      if [ -f "$spec/.spec-meta.json" ]; then
        name=$(basename "$spec")
        phase=$(jq -r ".phase" "$spec/.spec-meta.json")
        echo "  - $name (phase: $phase)"
      fi
    done
  else
    echo "No specs found. Initialize with: /spec:init <feature-name>"
  fi
fi
' -- "$1"`
