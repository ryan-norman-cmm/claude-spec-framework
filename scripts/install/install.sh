#!/bin/bash
# Claude Spec Framework Installer

set -e

VERSION="1.0.0"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; }

# Check dependencies
check_dependencies() {
  info "Checking dependencies..."

  # Check for jq
  if ! command -v jq &> /dev/null; then
    warn "jq not found. Installing..."
    if command -v brew &> /dev/null; then
      brew install jq
    elif command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y jq
    else
      error "Please install jq manually: https://stedolan.github.io/jq/"
      exit 1
    fi
  fi
  success "Dependencies OK"
}

# Backup existing files (only for --force mode)
backup_existing() {
  if [ "$FORCE_OVERWRITE" = "true" ]; then
    if [ -d "$CLAUDE_DIR/agents" ] || [ -d "$CLAUDE_DIR/commands/spec" ]; then
      local timestamp=$(date +%Y%m%d_%H%M%S)
      local backup_dir="$CLAUDE_DIR/.backups/spec-framework-$timestamp"

      info "Creating backup at $backup_dir..."
      mkdir -p "$backup_dir"

      [ -d "$CLAUDE_DIR/agents" ] && cp -r "$CLAUDE_DIR/agents" "$backup_dir/" 2>/dev/null || true
      [ -d "$CLAUDE_DIR/commands/spec" ] && cp -r "$CLAUDE_DIR/commands/spec" "$backup_dir/" 2>/dev/null || true
      [ -d "$CLAUDE_DIR/hooks" ] && cp -r "$CLAUDE_DIR/hooks" "$backup_dir/" 2>/dev/null || true

      success "Backup created"
    fi
  fi
}

# Copy file only if it doesn't exist (or if force mode)
copy_if_new() {
  local src="$1"
  local dest="$2"
  local existed=false

  [ -f "$dest" ] && existed=true

  if [ ! -f "$dest" ] || [ "$FORCE_OVERWRITE" = "true" ]; then
    cp "$src" "$dest"
    if [ "$existed" = "true" ]; then
      echo "  ↻ $(basename "$dest") (updated)"
    else
      echo "  + $(basename "$dest") (new)"
    fi
  else
    echo "  - $(basename "$dest") (exists, skipped)"
  fi
}

# Install files
install_files() {
  info "Installing spec framework files..."

  # Create directories
  mkdir -p "$CLAUDE_DIR/agents"
  mkdir -p "$CLAUDE_DIR/commands/spec"
  mkdir -p "$CLAUDE_DIR/hooks"
  mkdir -p "$CLAUDE_DIR/scripts"
  mkdir -p "$CLAUDE_DIR/docs"

  # Copy agents
  echo "Installing agents:"
  for agent in "$SCRIPT_DIR/../../agents/"*.md; do
    copy_if_new "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
  done

  # Copy commands
  echo ""
  echo "Installing commands:"
  for cmd in "$SCRIPT_DIR/../../commands/spec/"*.md; do
    copy_if_new "$cmd" "$CLAUDE_DIR/commands/spec/$(basename "$cmd")"
  done

  # Copy hooks (with user confirmation)
  if [ "$SKIP_HOOKS" != "true" ]; then
    echo ""
    echo "Installing hooks:"
    for hook in "$SCRIPT_DIR/../../hooks/"*.sh; do
      dest="$CLAUDE_DIR/hooks/$(basename "$hook")"
      existed=false
      [ -f "$dest" ] && existed=true

      if [ ! -f "$dest" ] || [ "$FORCE_OVERWRITE" = "true" ]; then
        cp "$hook" "$dest"
        chmod +x "$dest"
        if [ "$existed" = "true" ]; then
          echo "  ↻ $(basename "$hook") (updated)"
        else
          echo "  + $(basename "$hook") (new)"
        fi
      else
        echo "  - $(basename "$hook") (exists, skipped)"
      fi
    done
  else
    info "Skipped hooks installation"
  fi

  # Copy scripts
  echo ""
  echo "Installing scripts:"
  for script in "$SCRIPT_DIR/../utils/"*.sh; do
    dest="$CLAUDE_DIR/scripts/$(basename "$script")"
    existed=false
    [ -f "$dest" ] && existed=true

    if [ ! -f "$dest" ] || [ "$FORCE_OVERWRITE" = "true" ]; then
      cp "$script" "$dest"
      chmod +x "$dest"
      if [ "$existed" = "true" ]; then
        echo "  ↻ $(basename "$script") (updated)"
      else
        echo "  + $(basename "$script") (new)"
      fi
    else
      echo "  - $(basename "$script") (exists, skipped)"
    fi
  done

  # Copy docs
  echo ""
  echo "Installing documentation:"
  for doc in "$SCRIPT_DIR/../../docs/"*.md; do
    copy_if_new "$doc" "$CLAUDE_DIR/docs/$(basename "$doc")"
  done

  echo ""
  if [ "$FORCE_OVERWRITE" = "true" ]; then
    success "Force installation complete - all files updated"
  else
    success "Installation complete - new files added, existing files preserved"
  fi
}

# Configure hooks in settings.json
configure_hooks() {
  if [ "$SKIP_HOOKS" = "true" ]; then
    return
  fi

  local settings_file="$CLAUDE_DIR/settings.json"

  info "Configuring hooks in settings.json..."

  if [ ! -f "$settings_file" ]; then
    warn "No settings.json found, creating one..."
    echo '{"hooks":{}}' > "$settings_file"
  fi

  # Backup settings
  cp "$settings_file" "$settings_file.bak"

  # Add hooks using jq
  jq '.hooks.PreToolUse += [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/pre-tool-use-phase-gate.sh"
        }
      ]
    }
  ] | .hooks.PostToolUse += [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/post-tool-use-nx-quality.sh"
        },
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/post-tool-use-metadata-sync.sh"
        },
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/post-tool-use-tdd-tracking.sh"
        },
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/post-tool-use-requirements-validation.sh"
        }
      ]
    }
  ] | .hooks.UserPromptSubmit += [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "'"$CLAUDE_DIR"'/hooks/user-prompt-workflow-guidance.sh"
        }
      ]
    }
  ]' "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"

  success "Hooks configured in settings.json"
  info "Backup saved to: $settings_file.bak"
}

# Verify installation
verify_installation() {
  info "Verifying installation..."

  local errors=0

  # Check agents
  [ -f "$CLAUDE_DIR/agents/spec-requirements-generator.md" ] || { error "Missing: spec-requirements-generator.md"; ((errors++)); }
  [ -f "$CLAUDE_DIR/agents/spec-design-generator.md" ] || { error "Missing: spec-design-generator.md"; ((errors++)); }
  [ -f "$CLAUDE_DIR/agents/spec-task-generator.md" ] || { error "Missing: spec-task-generator.md"; ((errors++)); }
  [ -f "$CLAUDE_DIR/agents/spec-completion-agent.md" ] || { error "Missing: spec-completion-agent.md"; ((errors++)); }
  [ -f "$CLAUDE_DIR/agents/requirements-importer.md" ] || { error "Missing: requirements-importer.md"; ((errors++)); }
  [ -f "$CLAUDE_DIR/agents/e2e-test-generator.md" ] || { error "Missing: e2e-test-generator.md"; ((errors++)); }

  # Check commands
  [ -f "$CLAUDE_DIR/commands/spec/init.md" ] || { error "Missing: spec/init.md"; ((errors++)); }

  # Check hooks (if installed)
  if [ "$SKIP_HOOKS" != "true" ]; then
    [ -x "$CLAUDE_DIR/hooks/post-tool-use-tdd-tracking.sh" ] || { error "Missing or not executable: post-tool-use-tdd-tracking.sh"; ((errors++)); }
  fi

  if [ $errors -eq 0 ]; then
    success "Installation verified successfully!"
  else
    error "Installation verification failed with $errors errors"
    exit 1
  fi
}

# Print usage
usage() {
  cat << EOF
Claude Spec Framework Installer v$VERSION

Usage: $0 [OPTIONS]

Options:
  --auto            Non-interactive installation with defaults
  --skip-hooks      Install without hooks (manual configuration needed)
  --force           Overwrite ALL existing files (creates backup first)
  --claude-dir DIR  Custom Claude Code directory (default: ~/.claude)
  --help            Show this help message

Examples:
  $0                    # Interactive - add new files only
  $0 --auto             # Automatic - add new files only
  $0 --force            # Overwrite everything with backup
  $0 --skip-hooks       # Install without hooks
EOF
}

# Parse arguments
SKIP_HOOKS=false
AUTO_MODE=false
FORCE_OVERWRITE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --auto)
      AUTO_MODE=true
      shift
      ;;
    --skip-hooks)
      SKIP_HOOKS=true
      shift
      ;;
    --force)
      FORCE_OVERWRITE=true
      shift
      ;;
    --claude-dir)
      CLAUDE_DIR="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Main installation
main() {
  echo ""
  echo "🎯 Claude Spec Framework Installer v$VERSION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  info "Installation directory: $CLAUDE_DIR"

  if [ "$FORCE_OVERWRITE" = "true" ]; then
    warn "FORCE MODE: Will overwrite all existing files (backup created)"
  else
    info "Default mode: Only new files added, existing files preserved"
  fi
  echo ""

  if [ "$AUTO_MODE" != "true" ]; then
    read -p "Continue with installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "Installation cancelled"
      exit 0
    fi
  fi

  check_dependencies
  backup_existing
  install_files
  configure_hooks
  verify_installation

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  success "Installation complete! 🎉"
  echo ""
  echo "Next steps:"
  echo "  1. Try it out: claude"
  echo "     Then type: /spec:init my-first-feature"
  echo ""
  echo "  2. Read docs: $CLAUDE_DIR/docs/spec-best-practices.md"
  echo ""
  echo "  3. Check hooks: $CLAUDE_DIR/hooks/README.md"
  echo ""
  info "Need help? Visit: https://github.com/ryan-norman-cmm/claude-spec-framework"
  echo ""
}

main
