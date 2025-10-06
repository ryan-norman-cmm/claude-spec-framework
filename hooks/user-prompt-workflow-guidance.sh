#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# User prompt hook for spec guidance and automatic spec detection
# - Provides contextual guidance based on active specs
# - Detects spec-worthy conversations and suggests creation
# - Invokes spec-session-manager for orchestration

set -e

# Read input from stdin
input=$(cat)

# Extract user prompt
user_prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# Directory configuration
SPECS_DIR="$HOME/.claude/specs"

# Project-scoped memory: use git root hash or current directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
PROJECT_HASH=$(echo -n "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
MEMORY_DIR="$HOME/.claude/memory/spec-sessions"
STATE_FILE="$MEMORY_DIR/${PROJECT_HASH}-${PROJECT_NAME}.json"

# Initialize state file if not exists
mkdir -p "$MEMORY_DIR"
if [ ! -f "$STATE_FILE" ]; then
    echo '{"project_root":"'$PROJECT_ROOT'","active_specs":[],"conversation_context":{"exchange_count":0},"metadata":{"created_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$STATE_FILE"
fi

# AUTOMATIC SPEC DETECTION
# Check if conversation is spec-worthy (Kiro-style)
spec_worthy=false
spec_indicators=0

# Detect keywords suggesting structured development work
if [[ "$user_prompt" == *"implement"* ]] || [[ "$user_prompt" == *"build"* ]] || [[ "$user_prompt" == *"create"* ]] || [[ "$user_prompt" == *"add feature"* ]]; then
    ((spec_indicators++))
fi

# Detect requirements discussion
if [[ "$user_prompt" == *"requirement"* ]] || [[ "$user_prompt" == *"user stor"* ]] || [[ "$user_prompt" == *"acceptance"* ]]; then
    ((spec_indicators++))
fi

# Detect architectural/design discussion
if [[ "$user_prompt" == *"design"* ]] || [[ "$user_prompt" == *"architect"* ]] || [[ "$user_prompt" == *"database"* ]] || [[ "$user_prompt" == *"API"* ]]; then
    ((spec_indicators++))
fi

# Detect multi-step work
if [[ "$user_prompt" == *"and"* ]] && [[ "$user_prompt" == *"then"* ]]; then
    ((spec_indicators++))
fi

# If 2+ indicators, suggest spec creation
if [ $spec_indicators -ge 2 ]; then
    spec_worthy=true
fi

# Check project-scoped state for conversation context
conversation_exchanges=$(jq -r '.conversation_context.exchange_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# If conversation has >3 exchanges about same topic, suggest spec
if [ $conversation_exchanges -ge 3 ]; then
    spec_worthy=true
fi

# Check for active specs in project-scoped state
active_spec=$(jq -r '.active_specs[0].name // empty' "$STATE_FILE" 2>/dev/null || echo "")
active_spec_phase=$(jq -r '.active_specs[0].phase // empty' "$STATE_FILE" 2>/dev/null || echo "")

# If no active spec and conversation is spec-worthy, suggest creation
if [ -z "$active_spec" ] && [ "$spec_worthy" = true ]; then
    # Check if user already declined spec creation recently
    last_decline=$(jq -r '.conversation_context.last_spec_decline // empty' "$STATE_FILE" 2>/dev/null || echo "")
    declined_recently=false
    if [ -n "$last_decline" ]; then
        # Don't suggest again within same session
        declined_recently=true
    fi

    if [ "$declined_recently" = false ]; then
        # INVOKE spec-session-manager for detection logic
        echo '{
            "message": "💡 This conversation covers multiple implementation steps and requirements.",
            "action": "suggest_spec_creation",
            "suggestions": [
                "Create a spec for structured development? This will generate:",
                "  - EARS format requirements (Given/When/Then/And)",
                "  - Technical design with pattern analysis",
                "  - 5-7 sequential tasks with TDD approach",
                "  - Automated task tracking and validation",
                "",
                "Start spec workflow: /spec init <feature-name>",
                "Or continue with ad-hoc development (not recommended for complex features)"
            ],
            "detected_indicators": {
                "implementation_keywords": true,
                "architectural_discussion": true,
                "multi_step_work": true
            }
        }'
        exit 0
    fi
fi

# If no active spec but not spec-worthy conversation
if [ -z "$active_spec" ]; then
    # No active specs, check if user is asking about specs
    if [[ "$user_prompt" == *"spec"* ]] || [[ "$user_prompt" == *"specification"* ]] || [[ "$user_prompt" == *"requirements"* ]]; then
        echo '{
            "message": "No active specs found. You can start a new spec workflow with: /spec init <feature-name>",
            "suggestions": [
                "Use /spec init <feature-name> to start a new specification",
                "Use /spec import github-issue <number> to import from GitHub",
                "Use /spec import jira <ticket-id> to import from JIRA",
                "Use /spec list to see all specs (currently none active)"
            ]
        }'
    else
        echo '{"message": ""}'
    fi
    exit 0
fi

# Active spec exists - provide contextual guidance
# Check if user is asking about implementation
if [ -n "$active_spec" ]; then
    if [[ "$user_prompt" == *"implement"* ]] || [[ "$user_prompt" == *"build"* ]] || [[ "$user_prompt" == *"create"* ]] || [[ "$user_prompt" == *"add"* ]]; then
        spec_path="./specs/$active_spec"
        if [ ! -d "$spec_path" ]; then
            # Spec in memory but not in current project
            echo '{
                "message": "Active spec '"'$active_spec'"' found in memory, but not in current project directory.",
                "suggestions": [
                    "Navigate to the project with this spec",
                    "Or use /spec switch to change active spec"
                ]
            }'
            exit 0
        fi

        phase="$active_spec_phase"

        case "$phase" in
            "requirements")
                echo '{
                    "message": "Active spec '"'$active_spec'"' is in requirements phase.",
                    "suggestions": [
                        "Complete requirements.md before proceeding to implementation",
                        "Use /spec requirements '"'$active_spec'"' to generate EARS format requirements",
                        "Review and refine requirements before moving to design phase"
                    ]
                }'
                ;;
            "design")
                echo '{
                    "message": "Active spec '"'$active_spec'"' is in design phase.",
                    "suggestions": [
                        "Complete design.md before proceeding to implementation",
                        "Use /spec design '"'$active_spec'"' to generate design with pattern analysis",
                        "Ensure all components and interfaces are defined",
                        "Review architectural decisions before moving to implementation"
                    ]
                }'
                ;;
            "implementation")
                echo '{
                    "message": "🚀 Active spec '"'$active_spec'"' is ready for implementation.",
                    "context": {
                        "spec_location": "'"$spec_path"'",
                        "tasks_file": "'"$spec_path/tasks.md"'",
                        "requirements_file": "'"$spec_path/requirements.md"'",
                        "design_file": "'"$spec_path/design.md"'"
                    },
                    "automation": {
                        "task_tracking": "Auto-tracking enabled via task-tracker agent",
                        "tdd_enforcement": "Tests required before implementation (tdd-enforcer)",
                        "real_time_validation": "Acceptance criteria checked on file changes"
                    },
                    "suggestions": [
                        "Follow the task breakdown in tasks.md (execute one task at a time)",
                        "Start tracking: /spec track '"'$active_spec'"'",
                        "Tests MUST be written before implementation (TDD enforced)",
                        "Validate against acceptance criteria in requirements.md",
                        "Check progress: /spec status"
                    ]
                }'
                ;;
            *)
                echo '{
                    "message": "Active spec '"'$active_spec'"' found.",
                    "context": {
                        "spec_location": "'"$spec_path"'",
                        "current_phase": "'"$phase"'"
                    }
                }'
                ;;
        esac
    elif [[ "$user_prompt" == *"status"* ]] || [[ "$user_prompt" == *"progress"* ]]; then
        # User is asking about status
        echo '{
            "message": "Active spec: '"'$active_spec'"' (phase: '"'$active_spec_phase'"')",
            "suggestions": [
                "Use /spec status to see detailed progress (from /memory)",
                "Use /spec validate '"'$active_spec'"' for quality score"
            ]
        }'
    else
        # General context about active spec
        echo '{
            "context": {
                "active_spec": "'"$active_spec"'",
                "phase": "'"$active_spec_phase"'",
                "note": "Following spec-driven workflow - automated tracking active"
            }
        }'
    fi
else
    # No active spec found
    echo '{"message": ""}'
fi