---
allowed-tools: Task
description: Complete spec with validation, tests, and commit
argument-hint: <feature-name>
---

Complete and finalize spec for feature: **$1**

Use the Task tool with subagent_type='general-purpose' and this prompt:

"Complete spec for feature: $1 using spec-completion-agent guidelines

**Agent to use**: spec-completion-agent

**Objective**: Validate spec is production-ready and create completion commit.

**Completion Checklist**:

1. **Validate Score ≥90**
   - Run: /spec:validate $1
   - Parse validation score from output
   - Must achieve ≥90/100

2. **Verify All Tasks Complete**
   - Read: ./specs/$1/tasks.md
   - Count tasks with Status: [x] Completed
   - Count total tasks
   - Must be 100% complete

3. **Run E2E Tests** (if exist)
   - Search for E2E test files: test/e2e/, e2e/, **/*.e2e.spec.ts
   - Run: npm run test:e2e OR npm test -- e2e
   - All tests must pass (exit code 0)
   - If no E2E tests found, warn but continue

4. **Run Quality Checks**
   - Lint: npm run lint (if script exists)
   - Type check: npm run type-check OR tsc --noEmit (if TS)
   - Build: npm run build (if script exists)
   - All must pass (exit code 0)

5. **Update Spec Metadata**
   - Update ./specs/$1/.spec-meta.json:
     {
       \"phase\": \"completed\",
       \"completed_at\": \"<current-ISO-8601-timestamp>\",
       \"validation_score\": <score>,
       \"all_tests_passing\": true,
       \"quality_checks_passing\": true
     }

6. **Create Completion Commit**
   Format:
   ```
   feat: complete $1

   Completed spec with X tasks:
   - ✅ All tasks implemented and tested
   - ✅ Validation score: XX/100
   - ✅ E2E tests passing: X suites
   - ✅ Quality checks passing

   Key features implemented:
   <list-from-requirements-US-titles>

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

**If ANY check fails**:
- Report specific failure
- List what needs fixing
- Do NOT update metadata
- Do NOT create commit
- Exit with clear error message

**Success Output**:
```
✅ Spec Completion Summary

Feature: $1
Status: COMPLETE ✅

📊 Metrics:
  - Tasks completed: X/X (100%)
  - Validation score: XX/100
  - E2E tests: XX passing
  - Quality checks: ✅ All passing

📝 Commit created: <hash>

🎉 Spec is production-ready!

Next steps:
  1. Review: git show
  2. Create PR: gh pr create
```

**Error Output Examples**:

If validation < 90:
```
❌ Cannot complete - Validation score: XX/100 (need ≥90)
Issues: <list>
```

If tasks incomplete:
```
❌ Cannot complete - Progress: X/Y tasks (XX%)
Incomplete: <list>
```

**Important**:
- All checks must pass before committing
- Use exact commit message format
- Update metadata only on success
- Provide clear next steps"
