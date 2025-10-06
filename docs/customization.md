# Customization Guide

Tailor Claude Spec Framework to your project's needs.

## Configuration Files

### User-Level Config

`~/.claude/spec-framework.config.json` - Global settings for all projects

```json
{
  "version": "1.0.0",
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync", "phase-gate"],
    "disabled": ["nx-quality", "requirements-validation"]
  },
  "specs_directory": "./specs",
  "auto_approve_tools": true,
  "nx_integration": true,
  "tdd_strict_mode": false
}
```

### Project-Level Config

`.spec-framework.json` in project root - Overrides user config

```json
{
  "specs_directory": "./features/specs",
  "hooks": {
    "disabled": ["nx-quality"]
  },
  "custom_validators": ["./scripts/validate-api.sh"]
}
```

## Hook Customization

### Disable Specific Hooks

```json
{
  "hooks": {
    "disabled": ["nx-quality", "requirements-validation"]
  }
}
```

### Enable Only Specific Hooks

```json
{
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync"],
    "disabled": ["*"]  // Disable all others
  }
}
```

### Custom Hook Scripts

Add your own hooks to `~/.claude/hooks/`:

```bash
# ~/.claude/hooks/post-tool-use-custom-linter.sh
#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Your custom validation logic
if [[ "$1" == "Write" ]] || [[ "$1" == "Edit" ]]; then
  file_path="$2"

  # Run custom linter
  if [[ "$file_path" == *.ts ]]; then
    npx eslint "$file_path" --fix
  fi
fi
```

Register in `settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-tool-use-custom-linter.sh"
          }
        ]
      }
    ]
  }
}
```

## Spec Directory Structure

### Default Structure

```
specs/
├── feature-1/
│   ├── requirements.md
│   ├── design.md
│   ├── tasks.md
│   └── .spec-meta.json
└── feature-2/
    └── ...
```

### Custom Structure

Configure alternate locations:

```json
{
  "specs_directory": "./docs/features",
  "spec_template_dir": "./templates/spec"
}
```

## Agent Customization

### Modify Agent Behavior

Edit agents in `~/.claude/agents/`:

**Example: Customize requirements generation**

```markdown
<!-- ~/.claude/agents/spec-requirements-generator.md -->

# Spec Requirements Generator

... (existing content) ...

## Custom Rules

- Always include performance requirements
- Generate security considerations for auth features
- Add accessibility criteria for UI components
```

### Project-Specific Agent Overrides

Create `.claude/agents/` in your project to override global agents:

```
my-project/
├── .claude/
│   └── agents/
│       └── spec-requirements-generator.md  # Project-specific override
└── ...
```

## TDD Customization

### Strict Mode

Enforce test-first development:

```json
{
  "tdd_strict_mode": true
}
```

Blocks implementation files unless test file exists first.

### Custom Test Patterns

```bash
# ~/.claude/spec-framework.config.json
{
  "test_patterns": [
    "*.spec.ts",
    "*.test.ts",
    "*.spec.js",
    "*.test.js",
    "**/__tests__/*.ts"
  ]
}
```

### Test Framework Detection

Override automatic detection:

```json
{
  "test_framework": "vitest",  // or "jest", "mocha"
  "test_command": "npm run test:unit"
}
```

## NX Integration

### Enable NX-Specific Features

```json
{
  "nx_integration": true,
  "nx_affected_check": true,
  "nx_quality_gate": {
    "run_affected_tests": true,
    "check_boundaries": true
  }
}
```

### Disable NX Features

```json
{
  "nx_integration": false,
  "hooks": {
    "disabled": ["nx-quality"]
  }
}
```

## Validation Customization

### Custom Validators

Add custom validation scripts:

```bash
# scripts/validate-security.sh
#!/bin/bash
spec_dir="$1"

# Check for security requirements
if ! grep -q "security" "$spec_dir/requirements.md"; then
  echo "⚠️  No security requirements found"
  exit 1
fi

echo "✅ Security requirements validated"
```

Configure:
```json
{
  "custom_validators": [
    "./scripts/validate-security.sh",
    "./scripts/validate-performance.sh"
  ]
}
```

### Validation Rules

```json
{
  "validation": {
    "require_ears_format": true,
    "min_user_stories": 2,
    "require_acceptance_criteria": true,
    "require_test_coverage": 80
  }
}
```

## Template Customization

### Custom Spec Templates

Create template directory:

```bash
mkdir -p ~/.claude/templates/spec

# Create custom templates
touch ~/.claude/templates/spec/requirements.template.md
touch ~/.claude/templates/spec/design.template.md
touch ~/.claude/templates/spec/tasks.template.md
```

**Example custom requirements template:**

```markdown
<!-- ~/.claude/templates/spec/requirements.template.md -->
# Requirements: {{FEATURE_NAME}}

## Business Context
<!-- Why are we building this? -->

## User Stories
<!-- EARS format user stories -->

## Non-Functional Requirements

### Performance
<!-- Performance criteria -->

### Security
<!-- Security requirements -->

### Accessibility
<!-- A11y requirements -->
```

Configure:
```json
{
  "spec_template_dir": "~/.claude/templates/spec"
}
```

## Workflow Customization

### Phase Order

Customize workflow phases:

```json
{
  "workflow": {
    "phases": ["requirements", "design", "tasks", "implementation", "validation"],
    "allow_skip": false,
    "require_validation": true
  }
}
```

### Auto-Progression

Automatically move to next phase:

```json
{
  "workflow": {
    "auto_progress": true,
    "auto_validate": true
  }
}
```

## Output Customization

### Status Line

Customize spec info in status line:

```bash
# ~/.claude/settings.json
{
  "statusLine": {
    "command": "...",
    "show_spec_info": true
  }
}
```

### Notification Preferences

```json
{
  "notifications": {
    "task_completion": true,
    "phase_change": true,
    "validation_errors": true,
    "requirements_unmapped": false
  }
}
```

## Environment Variables

Override config via environment:

```bash
export CLAUDE_SPEC_DIR="./custom-specs"
export CLAUDE_TDD_STRICT=true
export CLAUDE_SKIP_HOOKS="nx-quality,requirements-validation"

claude  # Start with custom settings
```

## Advanced: Hook Development

### Create Custom Hook

```bash
#!/bin/bash
# ~/.claude/hooks/post-tool-use-custom.sh

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CONFIG_FILE="${CLAUDE_DIR}/spec-framework.config.json"

# Load config
if [ -f "$CONFIG_FILE" ]; then
  CUSTOM_SETTING=$(jq -r '.custom_setting // "default"' "$CONFIG_FILE")
fi

# Your logic here
tool_name="$1"
args="${@:2}"

case "$tool_name" in
  Write|Edit|MultiEdit)
    # Handle file changes
    echo "Custom hook triggered for: $args"
    ;;
esac

exit 0
```

### Hook Best Practices

1. **Always set CLAUDE_DIR**
   ```bash
   CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
   ```

2. **Check config before acting**
   ```bash
   if [ -f "$CONFIG_FILE" ]; then
     ENABLED=$(jq -r '.hooks.custom_hook.enabled // false' "$CONFIG_FILE")
     [ "$ENABLED" = "false" ] && exit 0
   fi
   ```

3. **Exit codes matter**
   - `0` = Success, continue
   - `1` = Error, stop execution
   - `2` = Warning, continue with message

4. **Be fast** - Hooks run on every tool use
   ```bash
   # Cache expensive operations
   # Run in background if possible
   ```

## Example Configurations

### Minimal Setup

```json
{
  "hooks": {
    "enabled": ["tdd-tracking"]
  }
}
```

### Full-Featured Setup

```json
{
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync", "phase-gate", "requirements-validation"]
  },
  "nx_integration": true,
  "tdd_strict_mode": true,
  "validation": {
    "require_ears_format": true,
    "min_user_stories": 2,
    "require_test_coverage": 80
  },
  "custom_validators": [
    "./scripts/validate-security.sh",
    "./scripts/validate-performance.sh"
  ]
}
```

### Team Setup

```json
{
  "specs_directory": "./docs/specs",
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync"],
    "disabled": ["nx-quality"]
  },
  "workflow": {
    "require_validation": true,
    "auto_progress": false
  },
  "notifications": {
    "task_completion": true,
    "validation_errors": true
  }
}
```

## Troubleshooting

### Config Not Loading

1. Check JSON syntax: `jq '.' ~/.claude/spec-framework.config.json`
2. Verify file location: `ls -la ~/.claude/spec-framework.config.json`
3. Check permissions: `chmod 644 ~/.claude/spec-framework.config.json`

### Hooks Ignoring Config

1. Verify hook reads config:
   ```bash
   grep -n "CONFIG_FILE" ~/.claude/hooks/post-tool-use-*.sh
   ```

2. Test hook manually:
   ```bash
   bash -x ~/.claude/hooks/post-tool-use-tdd-tracking.sh Write test.ts
   ```

### Custom Validators Not Running

1. Make executable: `chmod +x ./scripts/validate-*.sh`
2. Check shebang: First line should be `#!/bin/bash`
3. Test manually: `./scripts/validate-security.sh specs/feature-name`

---

**Need more customization?** Open an issue with your use case!
