# Hook System Guide

Understanding the Claude Spec Framework automation hooks.

## Overview

Hooks are **zero-token bash scripts** that run automatically in response to tool calls, providing real-time workflow automation.

### Why Hooks?

- ✅ **Zero tokens** - Pure bash, no AI calls
- ✅ **Instant execution** - Immediate feedback
- ✅ **Real-time sync** - Auto-updates as you work
- ✅ **Enforce quality** - Prevent common mistakes

## Hook Types

### 1. Pre-Tool-Use Hooks

Run **before** a tool executes - can block execution.

#### Phase Gate Hook

**File**: `pre-tool-use-phase-gate.sh`

**Purpose**: Enforce workflow order

**Prevents**:
- Implementing before designing
- Designing before requirements
- Creating files during wrong phase

**Example**:
```bash
# Trying to implement during requirements phase
Write("src/feature.ts", ...)
→ ❌ BLOCKED: Cannot create implementation files during requirements phase
→ Complete requirements first, then run /spec:design
```

**Configuration**:
```json
{
  "hooks": {
    "phase_gate": {
      "enforce": true,
      "allow_skip": false
    }
  }
}
```

---

### 2. Post-Tool-Use Hooks

Run **after** a tool completes successfully.

#### TDD Tracking Hook

**File**: `post-tool-use-tdd-tracking.sh`

**Purpose**: Auto-track Red-Green-Refactor cycle

**Detects**:
1. 🔴 **Red**: Test files created → Marks "Tests written and failing"
2. 🟢 **Green**: Tests pass → Marks "Implementation complete" + "Tests passing"
3. ♻️ **Refactor**: Code changes while tests pass → Maintains Green state

**Example Workflow**:
```bash
# Step 1: Write failing test
Write("src/user.spec.ts", ...)
→ Hook detects test file
→ Runs: npm test -- src/user.spec.ts
→ Tests fail
→ Marks: [x] Tests written and failing (Red)

# Step 2: Implement feature
Write("src/user.ts", ...)
→ Hook detects implementation file
→ Marks: [x] Implementation complete

# Step 3: Tests pass
→ Hook re-runs tests
→ Tests pass
→ Marks: [x] Tests passing (Green)
→ Status: [x] Completed
```

**Supports**:
- Jest (`npm test -- <file>`)
- Vitest (`npm test -- <file>`)
- Mocha (`npm test -- <file>`)

**Configuration**:
```json
{
  "tdd_tracking": {
    "enabled": true,
    "strict_mode": false,
    "test_patterns": ["*.spec.ts", "*.test.ts"]
  }
}
```

#### Metadata Sync Hook

**File**: `post-tool-use-metadata-sync.sh`

**Purpose**: Keep `.spec-meta.json` current

**Updates**:
- Last modified timestamp
- Modified files list
- Phase transitions
- Task progress

**Example**:
```bash
Write("specs/auth/design.md", ...)
→ Updates .spec-meta.json:
  {
    "last_modified": "2025-10-06T10:30:00Z",
    "phase": "design",
    "modified_files": ["design.md"]
  }
```

#### Requirements Validation Hook

**File**: `post-tool-use-requirements-validation.sh`

**Purpose**: Validate EARS criteria are tested

**Checks**:
1. Extracts EARS criteria from requirements.md
2. Maps criteria to current task
3. Searches test files for criterion terms
4. Reports unvalidated criteria

**Example Output**:
```bash
🔍 Validating requirements for Task 1...

✅ Criterion: "user is authenticated" - Found in auth.spec.ts
✅ Criterion: "displays profile" - Found in profile.spec.ts
⚠️  Criterion: "shows avatar" - NOT FOUND in tests

📋 Requirements mapping:
  - 2/3 criteria validated (67%)
  - 1 criterion needs test coverage
```

#### NX Quality Hook (Optional)

**File**: `post-tool-use-nx-quality.sh`

**Purpose**: NX monorepo quality checks

**Checks**:
- Boundary rules (enforce module boundaries)
- Affected tests (run tests for changed code)
- Build integrity

**Disable if not using NX**:
```json
{
  "hooks": {
    "disabled": ["nx-quality"]
  }
}
```

---

### 3. User-Prompt-Submit Hooks

Run **before** user prompt is sent to Claude.

#### Workflow Guidance Hook

**File**: `user-prompt-workflow-guidance.sh`

**Purpose**: Contextual suggestions based on spec phase

**Provides**:
- Next step recommendations
- Phase-specific tips
- Common command suggestions

**Example**:
```bash
# During requirements phase
User types: "help"

→ Hook injects:
💡 You're in the requirements phase
   Next steps:
   1. Review requirements in specs/feature/requirements.md
   2. Run /spec:design <feature> to generate design
   3. Edit requirements if needed, then /spec:refine

# During implementation phase
User types: "done with task 1"

→ Hook injects:
💡 Task 1 marked complete
   Next steps:
   1. Start Task 2 (see tasks.md)
   2. Run /spec:status to check progress
   3. Run /spec:validate before PR
```

---

## Hook Execution Flow

### Typical File Change Flow

```
User action: Write("src/feature.ts", ...)
  ↓
[Pre-Tool-Use] Phase Gate Hook
  ↓
  Checks: Current phase allows implementation?
  ↓
  If NO → BLOCK with helpful message
  If YES → Continue
  ↓
[Tool Executes] Write creates file
  ↓
[Post-Tool-Use Hooks] (in parallel)
  ↓
  ├─→ TDD Tracking Hook
  │     - Detects test file or implementation
  │     - Runs tests if test files exist
  │     - Updates task checkboxes
  │
  ├─→ Metadata Sync Hook
  │     - Updates .spec-meta.json
  │     - Records timestamp
  │
  ├─→ Requirements Validation Hook
  │     - Maps EARS criteria to tests
  │     - Reports coverage
  │
  └─→ NX Quality Hook (if enabled)
        - Checks boundaries
        - Runs affected tests
```

## Hook Configuration

### Global Settings

`~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-tool-use-phase-gate.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-tool-use-tdd-tracking.sh"
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/post-tool-use-metadata-sync.sh"
          }
        ]
      }
    ]
  }
}
```

### Framework Settings

`~/.claude/spec-framework.config.json`:
```json
{
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync"],
    "disabled": ["nx-quality"],
    "tdd_tracking": {
      "strict_mode": false,
      "test_patterns": ["*.spec.ts", "*.test.ts"]
    }
  }
}
```

## Debugging Hooks

### Enable Debug Mode

```bash
# Run hook manually with debug output
bash -x ~/.claude/hooks/post-tool-use-tdd-tracking.sh Write src/feature.ts
```

### Check Hook Output

```bash
# View recent hook executions
tail -f ~/.claude/hook-debug.log
```

### Test Individual Hook

```bash
# Simulate tool call
./hooks/post-tool-use-tdd-tracking.sh Write src/feature.spec.ts

# Expected output:
🔴 Task 1: Tests written but failing (Red phase)
```

## Common Issues

### Hook Not Triggering

**Symptom**: Tasks not auto-updating

**Check**:
1. Hook is executable:
   ```bash
   ls -la ~/.claude/hooks/*.sh
   # Should show: -rwxr-xr-x
   ```

2. Hook is registered:
   ```bash
   cat ~/.claude/settings.json | jq '.hooks'
   ```

3. Spec phase is correct:
   ```bash
   cat specs/feature/.spec-meta.json | jq '.phase'
   # Should show: "implementation"
   ```

**Fix**:
```bash
chmod +x ~/.claude/hooks/*.sh
```

### Tests Not Detected

**Symptom**: Hook doesn't mark tests passing

**Check**:
1. Test command exists:
   ```bash
   cat package.json | jq '.scripts.test'
   ```

2. Test files match patterns:
   ```bash
   # Default patterns: *.spec.ts, *.test.ts, *.spec.js, *.test.js
   ls src/**/*.spec.ts
   ```

3. Tests actually pass:
   ```bash
   npm test -- src/feature.spec.ts
   ```

**Fix**:
Add custom test patterns:
```json
{
  "test_patterns": ["**/__tests__/*.ts", "*.spec.ts"]
}
```

### Hook Fails Silently

**Symptom**: Hook runs but no output

**Debug**:
```bash
# Check exit code
./hooks/post-tool-use-tdd-tracking.sh Write test.ts
echo $?
# 0 = success, non-zero = error
```

**Add logging**:
```bash
# Edit hook to log output
echo "Hook output: $output" >> ~/.claude/hook-debug.log
```

### Phase Gate Too Strict

**Symptom**: Blocked from normal operations

**Temporarily disable**:
```json
{
  "hooks": {
    "disabled": ["phase-gate"]
  }
}
```

**Or allow skip**:
```json
{
  "phase_gate": {
    "allow_skip": true
  }
}
```

## Writing Custom Hooks

### Template

```bash
#!/bin/bash
# Custom hook template

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CONFIG_FILE="${CLAUDE_DIR}/spec-framework.config.json"

# Load config
ENABLED=true
if [ -f "$CONFIG_FILE" ]; then
  ENABLED=$(jq -r '.hooks.my_custom_hook.enabled // true' "$CONFIG_FILE")
fi

# Exit early if disabled
[ "$ENABLED" = "false" ] && exit 0

# Hook logic
tool_name="$1"
args="${@:2}"

case "$tool_name" in
  Write|Edit|MultiEdit)
    file_path="$2"

    # Your custom logic here
    echo "✅ Custom hook processed: $file_path"
    ;;
esac

exit 0
```

### Best Practices

1. **Always check config** - Respect disabled hooks
2. **Fast execution** - Cache when possible
3. **Helpful output** - Clear, actionable messages
4. **Error handling** - Graceful failures
5. **Exit codes** - 0 = success, 1 = error, 2 = warning

### Register Custom Hook

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/my-custom-hook.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Performance

### Benchmarks

| Hook | Avg Time | Max Time |
|------|----------|----------|
| Phase Gate | 5ms | 20ms |
| TDD Tracking | 150ms* | 500ms* |
| Metadata Sync | 10ms | 30ms |
| Requirements Validation | 50ms | 200ms |

*Depends on test execution time

### Optimization Tips

1. **Cache test results** - Don't re-run passing tests
2. **Parallel execution** - Independent hooks run concurrently
3. **Skip when possible** - Early exits for non-applicable files
4. **Background jobs** - Long operations in background

## Advanced: Hook Coordination

### Shared State

Hooks can communicate via temp files:

```bash
# Hook 1: Write state
echo "test-failing" > /tmp/spec-state-$SPEC_NAME

# Hook 2: Read state
STATE=$(cat /tmp/spec-state-$SPEC_NAME 2>/dev/null)
if [ "$STATE" = "test-failing" ]; then
  # Act on state
fi
```

### Hook Dependencies

Ensure hook order in settings.json:
```json
{
  "PostToolUse": [
    {
      "matcher": "*",
      "hooks": [
        {"command": "hook-1.sh"},  // Runs first
        {"command": "hook-2.sh"}   // Runs second
      ]
    }
  ]
}
```

---

**Questions about hooks?** Check the [FAQ](faq.md) or open an issue!
