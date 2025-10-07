---
allowed-tools: Task, Bash(mkdir:*), Write, Read
description: Initialize new spec and generate all phases
argument-hint: <feature-name>
---

Initialize spec for feature: **$1**

**Pre-Setup: Gather User Direction**

Ask the user: **What should this feature do and who is it for?** (Brief description of user need and scope)

Wait for user response before proceeding.

---

**Setup Steps**:
1. Check if ./specs/$1 already exists using Read tool - if it exists, stop and report error
2. Create directory: `mkdir -p ./specs/$1`
3. Use Write tool to create ./specs/$1/.spec-meta.json with current timestamp

Use the Task tool with subagent_type='general-purpose' and this prompt:

"Orchestrate sequential spec generation for feature: $1

User Direction: [Insert user's response here]

CRITICAL: Launch claude agents for each phase:
- Requirements: spec-requirements-generator agent
- Design: spec-design-generator agent
- Tasks: spec-task-generator agent

Execute SEQUENTIALLY, waiting for each to complete:

**Phase 1: Requirements** → Use spec-requirements-generator agent and prompt: 'Generate requirements.md for: $1. User direction: [user response]. Template: ${CLAUDE_DIR:-$HOME/.claude}/specs/templates/requirements.md. Output: ./specs/$1/requirements.md. Update: ./specs/$1/.spec-meta.json (phase: requirements)'

**Phase 2: Design** → Use spec-design-generator agent and prompt: '1. Pattern analysis for: $1 (progressive disclosure). 2. Generate design.md using discovered patterns. Context: ./specs/$1/requirements.md (load only when needed). Output: ./specs/$1/design.md. Update: ./specs/$1/.spec-meta.json (phase: design)'

**Phase 3: Tasks** → Use spec-task-generator agent and prompt: 'Generate tasks.md for: $1. Input: ./specs/$1/requirements.md + design.md (JIT loading). Output: ./specs/$1/tasks.md. Update: ./specs/$1/.spec-meta.json (phase: implementation)'

Verify each output file exists before proceeding. Report when complete."
