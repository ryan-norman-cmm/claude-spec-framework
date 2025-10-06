#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Post-tool-use hook for spec synchronization and automated tracking
# - Logs file modifications
# - Invokes task-tracker agent for completion detection
# - Invokes acceptance-validator for real-time validation

set -e

# Read input from stdin
input=$(cat)

# Extract tool information
tool_name=$(echo "$input" | jq -r '.tool.name // empty' 2>/dev/null || echo "")
tool_result=$(echo "$input" | jq -r '.result.success // false' 2>/dev/null || echo "false")
file_path=$(echo "$input" | jq -r '.tool.parameters.file_path // empty' 2>/dev/null || echo "")

# Directory configuration
SPECS_DIR="$HOME/.claude/specs"

# Project-scoped memory: use git root hash or current directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
PROJECT_HASH=$(echo -n "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
MEMORY_DIR="$HOME/.claude/memory/spec-sessions"
STATE_FILE="$MEMORY_DIR/${PROJECT_HASH}-${PROJECT_NAME}.json"

# Initialize state file if not exists
if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$MEMORY_DIR"
    echo '{"project_root":"'$PROJECT_ROOT'","active_specs":[],"metadata":{"created_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$STATE_FILE"
fi

# Only process successful file operations
if [ "$tool_result" != "true" ]; then
    echo '{"message": "Tool operation was not successful, no spec sync needed"}'
    exit 0
fi

# Check for active specs in project-scoped state
active_spec=""
active_spec_path=""

# Read active spec from project-scoped state file
active_spec=$(jq -r '.active_specs[0].name // empty' "$STATE_FILE" 2>/dev/null || echo "")
if [ -n "$active_spec" ]; then
    # Check current directory for spec
    if [ -d "./specs/$active_spec" ]; then
        active_spec_path="./specs/$active_spec"
    fi
fi

# If no active spec found, exit early
if [ -z "$active_spec_path" ]; then
    echo '{"message": "No active spec in current project"}'
    exit 0
fi

# Process file modification tools
case "$tool_name" in
    "Edit"|"Write"|"MultiEdit"|"NotebookEdit")
        if [ -n "$file_path" ]; then
            meta_file="$active_spec_path/.spec-meta.json"

            # Update last_updated timestamp
            if [ -f "$meta_file" ]; then
                temp_file=$(mktemp)
                jq '.updated_at = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' "$meta_file" > "$temp_file" && mv "$temp_file" "$meta_file"

                # Log the modification for tracking
                log_file="$active_spec_path/.modifications.log"
                echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $tool_name: $file_path" >> "$log_file"

                # INVOKE TASK-TRACKER AGENT for completion detection
                # Check if file is part of current task
                if [ -f "$active_spec_path/tasks.md" ]; then
                    # Signal to invoke task-tracker agent
                    # (In actual implementation, this would trigger agent via Claude Code)
                    echo "{\"message\": \"📋 Task tracker: File modified ($file_path)\", \"action\": \"check_task_completion\", \"spec\": \"$active_spec\", \"file\": \"$file_path\"}"

                    # Update project-scoped state with modification
                    temp_file=$(mktemp)
                    jq '.active_specs[0].last_modification = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" | .active_specs[0].modified_files += ["'$file_path'"]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE" 2>/dev/null || true
                else
                    echo "{\"message\": \"Spec '$active_spec' sync: logged modification of $file_path\"}"
                fi

                # INVOKE COMPREHENSIVE-VALIDATOR for real-time validation
                # Only for implementation files (not tests, not spec docs)
                if [[ ! "$file_path" == *".spec."* ]] && [[ ! "$file_path" == *".test."* ]] && [[ ! "$file_path" == *"/specs/"* ]]; then
                    # Check if this is an implementation file mentioned in tasks
                    if grep -q "$(basename "$file_path")" "$active_spec_path/tasks.md" 2>/dev/null; then
                        echo "{\"validation\": \"triggered\", \"message\": \"🔍 Real-time validation: Checking EARS criteria and code quality for $file_path\"}"
                    fi
                fi
            else
                echo '{"message": "Unable to update spec metadata"}'
            fi
        else
            echo '{"message": "No file path to track"}'
        fi
        ;;
    "Bash")
        # Track test execution or build commands
        command=$(echo "$input" | jq -r '.tool.parameters.command // empty' 2>/dev/null || echo "")
        if [[ "$command" == *"test"* ]] || [[ "$command" == *"build"* ]] || [[ "$command" == *"lint"* ]]; then
            log_file="$active_spec_path/.validations.log"
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Executed: $command" >> "$log_file"

            # INVOKE TASK-TRACKER for test cycle detection (Red/Green)
            if [[ "$command" == *"test"* ]]; then
                echo "{\"message\": \"🧪 Test execution detected\", \"action\": \"validate_tdd_cycle\", \"spec\": \"$active_spec\", \"command\": \"$command\"}"

                # Update project-scoped state
                temp_file=$(mktemp)
                jq '.active_specs[0].last_test_run = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE" 2>/dev/null || true
            else
                echo "{\"message\": \"Spec '$active_spec' sync: logged validation command\"}"
            fi
        else
            echo '{"message": "Command not relevant for spec tracking"}'
        fi
        ;;
    *)
        echo '{"message": "Tool not relevant for spec sync"}'
        ;;
esac