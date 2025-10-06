---
allowed-tools: Task
description: Sync spec with code changes (Code → Spec)
argument-hint: <feature-name>
---

Sync spec with codebase for feature: **$1**

Use the Task tool with subagent_type='general-purpose' and this prompt:

"Bi-directional sync: Code → Spec for feature: $1

**Objective**: Scan the codebase and update task completion status based on actual implementation.

**Steps**:
1. Read ./specs/$1/tasks.md to understand all tasks
2. For each task, analyze the codebase to determine if it's been implemented:
   - Check if files mentioned in the task exist
   - Verify if the functionality described is present in the code
   - Look for test files matching the task requirements
3. Update ./specs/$1/tasks.md with accurate task statuses:
   - Status: [x] - Task is fully implemented
   - Status: [ ] - Task is not yet started or incomplete
4. Update ./specs/$1/.spec-meta.json with:
   - last_sync: current timestamp
   - tasks_completed: count of completed tasks
   - tasks_total: total task count
5. Report sync results to user (X/Y tasks completed)

**Important**:
- Only mark tasks as completed if implementation is verified
- Preserve all other task content (don't rewrite tasks)
- Use exact string replacement for status checkboxes only"
