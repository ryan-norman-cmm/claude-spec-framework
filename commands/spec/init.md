---
allowed-tools: Task, Bash(mkdir:*), Bash(git:*), Write, Read
description: Initialize new spec and generate all phases
argument-hint: <feature-name>
---

Initialize spec for feature: **$1**

**Git Branch Setup (NEW)**:
IMPORTANT: Before creating spec files, set up git branch:
1. Source git utilities: `source ./scripts/utils/git-utils.sh`
2. Validate preconditions:
   - Check if on main branch using `is_on_main_branch` - if not, stop and report error
   - Check if working directory is clean using `check_clean_working_directory` - if not, stop and report error
3. Create and checkout branch: `create_spec_branch "$1"` - this creates and checks out to `spec/$1`
4. If branch creation fails, stop and report error

**Setup Steps**:
1. Check if ./specs/$1 already exists using Read tool - if it exists, stop and report error
2. Create directory: `mkdir -p ./specs/$1`
3. Use Write tool to create ./specs/$1/.spec-meta.json with:
   ```json
   {
     "feature": "$1",
     "created": "<current-timestamp>",
     "phase": "initialization",
     "lastUpdated": "<current-timestamp>",
     "branchName": "spec/$1"
   }
   ```

Orchestrate sequential spec generation for feature: $1

NEXT: Ask the user for general guidance on the problem being solved and the desired approach.
DO NOT progress until user responds.

CRITICAL: Launch specialized agents for each phase. DO NOT generate spec files yourself.

Execute SEQUENTIALLY, waiting for each to complete:

**Phase 1: Requirements** → Use spec-requirements-generator agent and prompt: 'Generate requirements.md for: $1. Template: ~/.claude/specs/templates/requirements.md. Output: ./specs/$1/requirements.md. Update: ./specs/$1/.spec-meta.json (phase: requirements)'

**Phase 2: Design** → Use spec-design-generator agent and prompt: '1. Pattern analysis for: $1 (progressive disclosure). 2. Generate design.md using discovered patterns. Context: ./specs/$1/requirements.md (load only when needed). Output: ./specs/$1/design.md. Update: ./specs/$1/.spec-meta.json (phase: design)'

**Phase 3: Tasks** → Use spec-task-generator agent and prompt: 'Generate tasks.md for: $1. Input: ./specs/$1/requirements.md + design.md (JIT loading). Output: ./specs/$1/tasks.md. Update: ./specs/$1/.spec-meta.json (phase: implementation)'

Verify each output file exists before proceeding. Report when complete."
