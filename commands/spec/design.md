---
allowed-tools: Task
description: Generate design.md via spec-design-generator
argument-hint: <feature-name>
---

Generate design for feature: **$1**

Use the Task tool with subagent_type='spec-design-generator' and this prompt:

"1. Pattern analysis for: $1 (progressive disclosure)
2. Generate design.md using discovered patterns

Context: ./specs/$1/requirements.md (load only when needed)
Output: ./specs/$1/design.md
Update: ./specs/$1/.spec-meta.json (phase: design)"
