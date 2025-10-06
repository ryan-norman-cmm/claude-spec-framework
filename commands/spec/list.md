---
allowed-tools: Bash(test:*), Bash(jq:*), Bash(basename:*)
description: List all specs with details
---

All specs: !`bash -c '
echo "📋 All Specs:"
echo ""
if [ -d "./specs" ]; then
  for spec in ./specs/*/; do
    if [ -f "$spec/.spec-meta.json" ]; then
      name=$(basename "$spec")
      phase=$(jq -r ".phase" "$spec/.spec-meta.json")
      updated=$(jq -r ".updated_at" "$spec/.spec-meta.json")
      echo "  - $name (phase: $phase, updated: $updated)"
    fi
  done
else
  echo "No specs found. Initialize with: /spec:init <feature-name>"
fi
'`
