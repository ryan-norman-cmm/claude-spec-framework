---
allowed-tools: Task, Bash(mkdir:*), Write, Read
description: Initialize new spec and generate all phases
argument-hint: <feature-name>
---

Initialize spec for feature: **$1**

**Setup Steps**:
1. Check if ./specs/$1 already exists using Read tool - if it exists, stop and report error
2. Create directory: `mkdir -p ./specs/$1`
3. Use Write tool to create ./specs/$1/.spec-meta.json with current timestamp

Use the Task tool with subagent_type='general-purpose' and this prompt:

"Orchestrate sequential spec generation for feature: $1

⚠️ CRITICAL: Launch specialized agents for each phase via Task tool. DO NOT generate spec files yourself.

Execute SEQUENTIALLY, waiting for each to complete:

**Phase 1: Requirements** → Use Task tool with subagent_type='spec-requirements-generator' and prompt: 'Generate requirements.md for: $1. Template: ${CLAUDE_DIR:-$HOME/.claude}/specs/templates/requirements.md. Output: ./specs/$1/requirements.md. Update: ./specs/$1/.spec-meta.json (phase: requirements)'

**Phase 2: Design** → Use Task tool with subagent_type='spec-design-generator' and prompt: '1. Pattern analysis for: $1 (progressive disclosure). 2. Generate design.md using discovered patterns. Context: ./specs/$1/requirements.md (load only when needed). Output: ./specs/$1/design.md. Update: ./specs/$1/.spec-meta.json (phase: design)'

**Phase 3: Tasks** → Use Task tool with subagent_type='spec-task-generator' and prompt: 'Generate tasks.md for: $1. Input: ./specs/$1/requirements.md + design.md (JIT loading). Output: ./specs/$1/tasks.md. Update: ./specs/$1/.spec-meta.json (phase: implementation)'

Verify each output file exists before proceeding. Report when complete."
