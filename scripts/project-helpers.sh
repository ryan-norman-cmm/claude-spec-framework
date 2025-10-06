#!/bin/bash

# Project-scoped helper functions for spec workflow
# Enables isolation of spec state across different projects on same machine

# Get project hash (8 chars of sha256)
# Uses git repository root for consistent hashing
get_project_hash() {
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    project_path="${git_root:-$PWD}"

    # macOS uses shasum instead of sha256sum
    if command -v sha256sum &> /dev/null; then
        echo -n "$project_path" | sha256sum | cut -c1-8
    elif command -v shasum &> /dev/null; then
        echo -n "$project_path" | shasum -a 256 | cut -c1-8
    else
        # Fallback: use simple hash
        echo -n "$project_path" | md5 | cut -c1-8
    fi
}

# Get project name from git repository or directory
get_project_name() {
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$git_root" ]; then
        basename "$git_root"
    else
        basename "$PWD"
    fi
}

# Get project-specific state file path
get_project_state_file() {
    local hash=$(get_project_hash)
    local name=$(get_project_name)
    echo "$HOME/.claude/memory/spec-sessions/${hash}-${name}.json"
}

# Get project root directory
get_project_root() {
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    echo "${git_root:-$PWD}"
}

# Get git remote URL if available
get_git_remote() {
    git remote get-url origin 2>/dev/null || echo ""
}

# Initialize project state file if it doesn't exist
init_project_state() {
    local state_file="$1"
    local project_root=$(get_project_root)
    local project_name=$(get_project_name)
    local git_remote=$(get_git_remote)

    if [ ! -f "$state_file" ]; then
        mkdir -p "$(dirname "$state_file")"
        cat > "$state_file" <<EOF
{
  "project_root": "$project_root",
  "project_name": "$project_name",
  "git_remote": "$git_remote",
  "active_specs": [],
  "conversation_context": {
    "exchange_count": 0,
    "feature_discussed": null,
    "suggested_spec": false,
    "last_decline": null
  },
  "metadata": {
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF
    fi
}

# Update global index with current project info
update_global_index() {
    local hash=$(get_project_hash)
    local name=$(get_project_name)
    local root=$(get_project_root)
    local global_file="$HOME/.claude/memory/spec-sessions/global-state.json"

    # Initialize global index if not exists
    if [ ! -f "$global_file" ]; then
        mkdir -p "$(dirname "$global_file")"
        echo '{"projects":{},"recent_projects":[],"last_active_project":null}' > "$global_file"
    fi

    # Count active specs for this project
    local state_file=$(get_project_state_file)
    local spec_count=0
    if [ -f "$state_file" ]; then
        spec_count=$(jq '.active_specs | length' "$state_file" 2>/dev/null || echo 0)
    fi

    # Update project entry in global index
    temp_file=$(mktemp)
    jq --arg hash "$hash" \
       --arg name "$name" \
       --arg root "$root" \
       --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --argjson count "$spec_count" \
       '.projects[$hash] = {"name": $name, "root": $root, "last_activity": $ts, "active_specs_count": $count} |
        .last_active_project = $hash |
        .recent_projects = ([$hash] + .recent_projects | unique | .[0:10])' \
       "$global_file" > "$temp_file" && mv "$temp_file" "$global_file"
}

# Get all projects from global index
list_all_projects() {
    local global_file="$HOME/.claude/memory/spec-sessions/global-state.json"

    if [ -f "$global_file" ]; then
        jq -r '.projects | to_entries | .[] | "\(.key) \(.value.name) \(.value.active_specs_count) \(.value.last_activity)"' "$global_file"
    fi
}

# Find spec across all projects
search_spec_global() {
    local spec_name="$1"
    local memory_dir="$HOME/.claude/memory/spec-sessions"

    for state_file in "$memory_dir"/*-*.json; do
        if [ -f "$state_file" ]; then
            # Check if this project has the spec
            local has_spec=$(jq --arg name "$spec_name" '.active_specs[] | select(.name == $name) | .name' "$state_file" 2>/dev/null)
            if [ -n "$has_spec" ]; then
                local project_name=$(jq -r '.project_name' "$state_file")
                local project_root=$(jq -r '.project_root' "$state_file")
                local spec_phase=$(jq -r --arg name "$spec_name" '.active_specs[] | select(.name == $name) | .phase' "$state_file")
                echo "Found in: $project_name ($project_root)"
                echo "  Spec: $spec_name (phase: $spec_phase)"
            fi
        fi
    done
}

# Migrate old global state to project-scoped state (one-time migration)
migrate_legacy_state() {
    local old_state="$HOME/.claude/memory/spec-sessions/state.json"

    if [ -f "$old_state" ]; then
        echo "🔄 Migrating legacy state to project-scoped format..."

        # Backup old state
        cp "$old_state" "$old_state.backup"

        # Create new project state from current directory
        local new_state=$(get_project_state_file)
        init_project_state "$new_state"

        # Copy active specs to new state
        if jq -e '.active_specs' "$old_state" > /dev/null 2>&1; then
            temp_file=$(mktemp)
            jq --slurpfile old "$old_state" '.active_specs = $old[0].active_specs' "$new_state" > "$temp_file" && mv "$temp_file" "$new_state"
            echo "✅ Migrated active specs to: $new_state"
        fi

        # Update global index
        update_global_index

        # Rename old state so we don't migrate again
        mv "$old_state" "$old_state.migrated"
        echo "✅ Migration complete. Old state backed up to: $old_state.backup"
    fi
}

# Export functions for use in other scripts
export -f get_project_hash
export -f get_project_name
export -f get_project_state_file
export -f get_project_root
export -f get_git_remote
export -f init_project_state
export -f update_global_index
export -f list_all_projects
export -f search_spec_global
export -f migrate_legacy_state
