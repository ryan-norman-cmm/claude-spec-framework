---
allowed-tools: Task
description: Complete spec with validation, tests, and commit
argument-hint: <feature-name>
---

Complete and finalize spec for feature: **$1**

Use the Task tool with subagent_type='spec-completion-agent' and this prompt:

"Complete spec: $1

Follow spec-completion-agent workflow:
- Validate score ≥90
- All tasks complete
- E2E tests passing
- Quality checks passing
- Update metadata
- Create completion commit"
