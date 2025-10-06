#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Pre-tool-use hook for spec validation
# Validates that tool usage aligns with active spec tasks

set -e

# Read input from stdin
input=$(cat)

# Extract tool information
tool_name=$(echo "$input" | jq -r '.tool.name // empty' 2>/dev/null || echo "")
file_path=$(echo "$input" | jq -r '.tool.parameters.file_path // empty' 2>/dev/null || echo "")

# Directory configuration
SPECS_DIR="$HOME/.claude/specs"
ACTIVE_DIR="$SPECS_DIR/active"

# Check if any specs are currently active
if [ ! -d "$ACTIVE_DIR" ] || [ -z "$(ls -A "$ACTIVE_DIR" 2>/dev/null)" ]; then
    # No active specs, allow all operations
    echo '{"allow": true}'
    exit 0
fi

# Find the most recently updated active spec
latest_spec=""
latest_time=0
for spec_dir in "$ACTIVE_DIR"/*; do
    if [ -d "$spec_dir" ]; then
        meta_file="$spec_dir/.spec-meta.json"
        if [ -f "$meta_file" ]; then
            status=$(jq -r '.status // "unknown"' "$meta_file" 2>/dev/null)
            if [ "$status" = "in_progress" ]; then
                updated_time=$(date -r "$meta_file" +%s 2>/dev/null || echo 0)
                if [ "$updated_time" -gt "$latest_time" ]; then
                    latest_time="$updated_time"
                    latest_spec="$spec_dir"
                fi
            fi
        fi
    fi
done

# If no active spec in progress, allow operation
if [ -z "$latest_spec" ]; then
    echo '{"allow": true}'
    exit 0
fi

# Check if this is a file modification tool
case "$tool_name" in
    "Edit"|"Write"|"MultiEdit"|"NotebookEdit")
        if [ -n "$file_path" ]; then
            # Get the active spec name
            spec_name=$(basename "$latest_spec")
            tasks_file="$latest_spec/tasks.md"

            # Check if the file being modified is mentioned in current tasks
            if [ -f "$tasks_file" ]; then
                # Look for the file in the tasks marked as in progress
                if grep -q "$file_path" "$tasks_file" 2>/dev/null; then
                    echo "{\"allow\": true, \"message\": \"File modification aligns with spec: $spec_name\"}"
                else
                    # Provide a warning but don't block
                    echo "{\"allow\": true, \"warning\": \"Note: File $file_path is not mentioned in active spec '$spec_name'. Consider updating tasks.md if this is part of the implementation.\"}"
                fi
            else
                echo '{"allow": true}'
            fi
        else
            echo '{"allow": true}'
        fi
        ;;
    *)
        # Allow all other tools
        echo '{"allow": true}'
        ;;
esac