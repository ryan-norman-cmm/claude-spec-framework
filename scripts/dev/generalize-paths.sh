#!/bin/bash
# Generalize hardcoded paths to make framework portable

set -e

TARGET_DIR="$(pwd)"

echo "🔧 Generalizing hardcoded paths..."
echo ""

# Function to replace paths in a file
generalize_file() {
  local file="$1"

  if [ ! -f "$file" ]; then
    return
  fi

  # Replace /Users/rnorman/.claude with ${CLAUDE_DIR:-$HOME/.claude}
  sed -i '' 's|/Users/rnorman/\.claude|\${CLAUDE_DIR:-$HOME/.claude}|g' "$file" 2>/dev/null || \
    sed -i 's|/Users/rnorman/\.claude|\${CLAUDE_DIR:-$HOME/.claude}|g' "$file" 2>/dev/null

  # Replace ~/.claude with ${CLAUDE_DIR:-$HOME/.claude}
  sed -i '' 's|~/\.claude|\${CLAUDE_DIR:-$HOME/.claude}|g' "$file" 2>/dev/null || \
    sed -i 's|~/\.claude|\${CLAUDE_DIR:-$HOME/.claude}|g' "$file" 2>/dev/null

  echo "✅ Generalized: $file"
}

# Process all shell scripts
echo "📜 Processing shell scripts..."
find hooks scripts -type f -name "*.sh" | while read -r file; do
  generalize_file "$file"
done
echo ""

# Process markdown files (for documentation paths)
echo "📚 Processing markdown files..."
find agents commands docs -type f -name "*.md" | while read -r file; do
  generalize_file "$file"
done
echo ""

# Add CLAUDE_DIR variable to all hook scripts
echo "🔧 Adding CLAUDE_DIR variable to hooks..."
for hook in hooks/*.sh; do
  if [ -f "$hook" ]; then
    # Check if CLAUDE_DIR is already set
    if ! grep -q "CLAUDE_DIR=" "$hook"; then
      # Add after shebang
      sed -i '' '2i\
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
' "$hook" 2>/dev/null || \
      sed -i '2i\CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"' "$hook" 2>/dev/null
      echo "✅ Added CLAUDE_DIR to: $(basename "$hook")"
    fi
  fi
done
echo ""

echo "✨ Path generalization complete!"
echo ""
echo "Summary:"
echo "  - Replaced hardcoded paths with \${CLAUDE_DIR:-\$HOME/.claude}"
echo "  - Added CLAUDE_DIR variable to hook scripts"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test a hook: hooks/post-tool-use-tdd-tracking.sh"
