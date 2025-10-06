#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Post-Tool-Use Hook: Nx Quality Checks on Affected Files
# Automatically runs nx format, nx lint, and nx test on affected files
# Only runs if nx.json exists in the project

TOOL_NAME=$1
FILE_PATH=$2

# Only run for file modification tools
if [[ ! "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
  exit 0
fi

# Only run if nx.json exists (Nx workspace)
if [ ! -f "nx.json" ]; then
  exit 0
fi

# Check if nx is installed
if ! command -v nx &> /dev/null && ! command -v npx &> /dev/null; then
  exit 0
fi

# Determine nx command (prefer local nx, fallback to npx)
NX_CMD="npx nx"
if command -v nx &> /dev/null; then
  NX_CMD="nx"
fi

echo ""
echo "🔧 Running Nx quality checks on affected files..."

# Track if any checks fail
quality_passed=true

# 1. Format affected files
echo "  📝 Formatting affected files..."
if $NX_CMD format:write --files="$FILE_PATH" 2>/dev/null; then
  echo "    ✅ Format complete"
else
  echo "    ⚠️  Format skipped (no formatter configured or file not in workspace)"
fi

# 2. Lint affected projects
echo "  🔍 Linting affected projects..."
affected_projects=$($NX_CMD show projects --affected --files="$FILE_PATH" 2>/dev/null)

if [ -n "$affected_projects" ]; then
  for project in $affected_projects; do
    # Check if project has lint target
    if $NX_CMD show project "$project" --json 2>/dev/null | jq -e '.targets.lint' > /dev/null 2>&1; then
      echo "    Linting $project..."
      if $NX_CMD lint "$project" 2>&1 | tee /tmp/nx-lint-output.txt; then
        echo "    ✅ $project lint passed"
      else
        echo "    ❌ $project lint failed"
        quality_passed=false
        # Show first 10 lines of errors
        head -10 /tmp/nx-lint-output.txt | sed 's/^/      /'
      fi
    fi
  done
else
  echo "    ℹ️  No affected projects found"
fi

# 3. Test affected projects
echo "  🧪 Testing affected projects..."

if [ -n "$affected_projects" ]; then
  for project in $affected_projects; do
    # Check if project has test target
    if $NX_CMD show project "$project" --json 2>/dev/null | jq -e '.targets.test' > /dev/null 2>&1; then
      echo "    Testing $project..."
      if $NX_CMD test "$project" --skip-nx-cache 2>&1 | tee /tmp/nx-test-output.txt; then
        echo "    ✅ $project tests passed"
      else
        echo "    ❌ $project tests failed"
        quality_passed=false
        # Show first 10 lines of errors
        head -10 /tmp/nx-test-output.txt | sed 's/^/      /'
      fi
    fi
  done
else
  echo "    ℹ️  No affected projects with tests"
fi

# Summary
echo ""
if [ "$quality_passed" = true ]; then
  echo "✅ All Nx quality checks passed"
else
  echo "⚠️  Some Nx quality checks failed - review output above"
fi

echo ""

# Exit 0 regardless (don't block tool execution)
exit 0
