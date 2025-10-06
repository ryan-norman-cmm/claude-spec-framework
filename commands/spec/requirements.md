---
allowed-tools: Task
description: Generate requirements.md via spec-requirements-generator
argument-hint: <feature-name>
---

Generate requirements for feature: **$1**

Use the Task tool with subagent_type='spec-requirements-generator' and this prompt:

"Generate requirements.md for: $1

Template reference: ${CLAUDE_DIR:-$HOME/.claude}/specs/templates/requirements.md
Output: ./specs/$1/requirements.md
Update: ./specs/$1/.spec-meta.json (phase: requirements)"
