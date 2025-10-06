---
allowed-tools: Task
description: Regenerate design + tasks from updated requirements (Spec → Code)
argument-hint: <feature-name>
---

Refine spec for feature: **$1**

Use the Task tool with subagent_type='general-purpose' and this prompt:

"Refine spec for: $1 (requirements → design → tasks)

⚠️ CRITICAL: Launch specialized agents via Task tool. DO NOT generate spec files yourself.

Execute SEQUENTIALLY:

**Phase 1: Design** → Use Task tool with subagent_type='spec-design-generator' and prompt: '1. Pattern analysis for: $1 (progressive disclosure). 2. Generate design.md using discovered patterns. Context: ./specs/$1/requirements.md (load only when needed). Output: ./specs/$1/design.md. Update: ./specs/$1/.spec-meta.json (phase: design)'

**Phase 2: Tasks** → Use Task tool with subagent_type='spec-task-generator' and prompt: 'Generate tasks.md for: $1. Input: ./specs/$1/requirements.md + design.md (JIT loading). Output: ./specs/$1/tasks.md. Update: ./specs/$1/.spec-meta.json (phase: implementation). Preserve completion status of existing tasks (match by title). Add new tasks for new requirements. Remove tasks for deleted requirements.'

**Phase 3: Report** changes to user after both agents complete:
- Design changes summary
- Tasks added/removed/preserved

Verify outputs exist before proceeding."
