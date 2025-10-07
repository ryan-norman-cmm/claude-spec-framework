# Scripts Directory

Organized scripts for the Claude Spec Framework.

## Directory Structure

```
scripts/
├── install/           # Installation scripts
│   └── install.sh     # Main installer (interactive, auto, force modes)
├── dev/               # Development utilities
│   ├── extract.sh     # Extract framework from ~/.claude
│   ├── generalize-paths.sh  # Make paths portable
│   └── test-install.sh      # Test installation in isolation
└── utils/             # Runtime utilities
    ├── project-helpers.sh    # Project-scoped helper functions
    └── spec-validator.sh     # Spec validation system
```

## Installation Scripts

### install/install.sh

Main framework installer with multiple modes:

```bash
./scripts/install/install.sh                # Interactive - add new files only
./scripts/install/install.sh --auto         # Non-interactive - add new files only
./scripts/install/install.sh --force        # Overwrite all (creates backup)
./scripts/install/install.sh --skip-hooks   # Install without hooks
```

**Features:**
- Selective file installation (new files only by default)
- Force mode with automatic backups
- Dependency checking (jq, git)
- Hook installation/configuration
- Status indicators (+, ↻, -)

## Development Scripts

### dev/extract.sh

Extract framework files from installed `~/.claude` directory:

```bash
./scripts/dev/extract.sh
```

Used for:
- Exporting installed framework to repository
- Capturing customizations
- Creating portable distribution

### dev/generalize-paths.sh

Generalize hardcoded paths for portability:

```bash
./scripts/dev/generalize-paths.sh
```

Replaces:
- `/Users/username/.claude` → `${CLAUDE_DIR:-$HOME/.claude}`
- `~/.claude` → `${CLAUDE_DIR:-$HOME/.claude}`

### dev/test-install.sh

Test installation in isolated environment:

```bash
./scripts/dev/test-install.sh
```

Creates temporary test directory and validates installation process.

## Utility Scripts

### utils/project-helpers.sh

Project-scoped helper functions sourced by hooks:

```bash
source ~/.claude/scripts/project-helpers.sh
```

**Functions:**
- `get_project_hash()` - Generate project identifier
- `get_project_name()` - Get project name from git/directory
- `get_project_specs_dir()` - Get specs directory path
- `get_current_spec()` - Detect current spec from context

**Use case:** Enables spec state isolation across different projects on the same machine.

### utils/spec-validator.sh

Spec validation system (legacy - mostly replaced by spec-comprehensive-validator agent):

```bash
~/.claude/scripts/spec-validator.sh <spec-name>
```

**Validates:**
- Requirements quality (EARS format)
- Design completeness
- Task structure
- File existence
- Requirements-to-code mapping

**Note:** Modern validation uses `/spec:validate` command with spec-comprehensive-validator agent.

## Usage in Hooks

Hooks source utility scripts for common functions:

```bash
#!/bin/bash
# Example hook

# Source project helpers
source "${CLAUDE_DIR:-$HOME/.claude}/scripts/project-helpers.sh"

# Use helper functions
PROJECT_HASH=$(get_project_hash)
SPEC_NAME=$(get_current_spec)
```

## Adding New Scripts

### Installation Script

Add to `scripts/install/` if:
- Related to framework installation
- Runs during setup/upgrade
- Modifies `~/.claude/` directory

### Development Script

Add to `scripts/dev/` if:
- Used during framework development
- Not run by end users
- Testing/extraction/build utilities

### Utility Script

Add to `scripts/utils/` if:
- Sourced by hooks or commands
- Provides reusable functions
- Runtime helper utilities

## Best Practices

1. **Portable Paths**: Use `${CLAUDE_DIR:-$HOME/.claude}` for framework paths
2. **Error Handling**: Use `set -e` and proper exit codes
3. **Colored Output**: Use consistent color variables (RED, GREEN, YELLOW, BLUE)
4. **Documentation**: Add header comments explaining purpose
5. **Dependencies**: Check for required tools (jq, git) before execution
6. **Idempotency**: Scripts should be safe to run multiple times

## Testing Scripts

Before committing script changes:

```bash
# Test installation
./scripts/dev/test-install.sh

# Test in force mode
CLAUDE_DIR=/tmp/test-claude ./scripts/install/install.sh --force

# Validate paths are portable
./scripts/dev/generalize-paths.sh
grep -r "/Users/" scripts/  # Should return no hardcoded paths
```
