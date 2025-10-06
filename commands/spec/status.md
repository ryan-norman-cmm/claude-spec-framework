---
allowed-tools: Bash(test:*), Bash(jq:*), Bash(grep:*), Bash(basename:*)
description: Show spec status and progress
argument-hint: [feature-name]
---

Spec status: !`bash -c '
FEATURE="$1"
if [ -n "$FEATURE" ]; then
  if [ -f "./specs/$FEATURE/.spec-meta.json" ]; then
    echo "📋 Spec: $FEATURE"
    echo ""
    jq -r "\"Phase: \(.phase)\nCreated: \(.created_at)\nUpdated: \(.updated_at)\nSource: \(.source // \"manual\")\"" "./specs/$FEATURE/.spec-meta.json"
    if [ -f "./specs/$FEATURE/tasks.md" ]; then
      total=$(grep -c "^### Task" "./specs/$FEATURE/tasks.md" 2>/dev/null || echo 0)
      completed=$(grep -c "^\- Status: \[x\]" "./specs/$FEATURE/tasks.md" 2>/dev/null || echo 0)
      echo "Tasks: $completed/$total completed"
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
