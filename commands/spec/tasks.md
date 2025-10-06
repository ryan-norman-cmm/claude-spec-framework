---
allowed-tools: Task
description: Generate tasks.md via spec-task-generator
argument-hint: <feature-name>
---

Generate tasks for feature: **$1**

Use the Task tool with subagent_type='spec-task-generator' and this prompt:

"Generate tasks.md for: $1

Input: ./specs/$1/requirements.md + design.md (JIT loading)
Output: ./specs/$1/tasks.md
Update: ./specs/$1/.spec-meta.json (phase: implementation)"
