---
allowed-tools: Task
description: Validate spec quality via spec-comprehensive-validator
argument-hint: <feature-name>
---

Validate spec for feature: **$1**

Use the Task tool with subagent_type='spec-comprehensive-validator' and this prompt:

"Validate spec: $1

Unified validation:
- Spec quality (completeness, consistency, MVP)
- EARS criteria → implementation mapping
- Code quality via /review (if code exists)

Output: ./specs/$1/validation-report.md (quality score 0-100)"
