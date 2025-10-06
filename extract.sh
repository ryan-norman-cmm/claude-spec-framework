#!/bin/bash
# Extraction script to copy spec framework files from ~/.claude

set -e

SOURCE_DIR="${HOME}/.claude"
TARGET_DIR="$(pwd)"

echo "🔍 Extracting Claude Spec Framework from ${SOURCE_DIR}"
echo "📦 Target directory: ${TARGET_DIR}"
echo ""

# Function to copy with status
copy_file() {
  local src="$1"
  local dest="$2"

  if [ -f "$src" ]; then
    cp "$src" "$dest"
    echo "✅ Copied: $(basename "$src")"
  else
    echo "⚠️  Missing: $src"
  fi
}

# 1. Copy agents
echo "📋 Copying agents..."
copy_file "${SOURCE_DIR}/agents/spec-requirements-generator.md" "agents/spec-requirements-generator.md"
copy_file "${SOURCE_DIR}/agents/spec-design-generator.md" "agents/spec-design-generator.md"
copy_file "${SOURCE_DIR}/agents/spec-task-generator.md" "agents/spec-task-generator.md"
copy_file "${SOURCE_DIR}/agents/spec-comprehensive-validator.md" "agents/spec-comprehensive-validator.md"
copy_file "${SOURCE_DIR}/agents/requirements-importer.md" "agents/requirements-importer.md"
copy_file "${SOURCE_DIR}/agents/task-completion-evaluator.md" "agents/task-completion-evaluator.md"
copy_file "${SOURCE_DIR}/agents/e2e-test-generator.md" "agents/e2e-test-generator.md"
echo ""

# 2. Copy commands
echo "📋 Copying slash commands..."
cp -r "${SOURCE_DIR}/commands/spec/"* "commands/spec/" 2>/dev/null || true
echo "✅ Copied spec commands"
echo ""

# 3. Copy hooks
echo "🪝 Copying hooks..."
copy_file "${SOURCE_DIR}/hooks/pre-tool-use-phase-gate.sh" "hooks/pre-tool-use-phase-gate.sh"
copy_file "${SOURCE_DIR}/hooks/post-tool-use-nx-quality.sh" "hooks/post-tool-use-nx-quality.sh"
copy_file "${SOURCE_DIR}/hooks/post-tool-use-metadata-sync.sh" "hooks/post-tool-use-metadata-sync.sh"
copy_file "${SOURCE_DIR}/hooks/post-tool-use-tdd-tracking.sh" "hooks/post-tool-use-tdd-tracking.sh"
copy_file "${SOURCE_DIR}/hooks/post-tool-use-requirements-validation.sh" "hooks/post-tool-use-requirements-validation.sh"
copy_file "${SOURCE_DIR}/hooks/user-prompt-workflow-guidance.sh" "hooks/user-prompt-workflow-guidance.sh"
copy_file "${SOURCE_DIR}/hooks/README.md" "hooks/README.md"
echo ""

# 4. Copy scripts
echo "📜 Copying scripts..."
copy_file "${SOURCE_DIR}/scripts/spec-validator.sh" "scripts/spec-validator.sh"
copy_file "${SOURCE_DIR}/scripts/project-helpers.sh" "scripts/project-helpers.sh"
echo ""

# 5. Copy docs
echo "📚 Copying documentation..."
copy_file "${SOURCE_DIR}/docs/spec-best-practices.md" "docs/spec-best-practices.md"
echo ""

# 6. Set permissions
echo "🔒 Setting permissions..."
chmod +x hooks/*.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
echo "✅ Permissions set"
echo ""

# 7. Summary
echo "✨ Extraction complete!"
echo ""
echo "Files extracted to:"
echo "  - agents/        (7 files)"
echo "  - commands/spec/ (10 files)"
echo "  - hooks/         (7 files)"
echo "  - scripts/       (2 files)"
echo "  - docs/          (1 file)"
echo ""
echo "Next steps:"
echo "  1. Run: ./generalize-paths.sh"
echo "  2. Review and commit files"
