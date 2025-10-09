---
allowed-tools: Task, Bash(source:*), Bash(jq:*), Read
description: Complete spec with validation, tests, and commit
argument-hint: <feature-name>
---

Complete and finalize spec for feature: **$1**

**PR Approval Check (NEW)**:
IMPORTANT: Before completing spec, verify PR is approved:

1. Read ./specs/$1/.spec-meta.json
2. Check if prUrl exists - if not, stop and report: "Error: No PR found. Run /spec:create-pr first"
3. Source gh-utils: `source ./scripts/utils/gh-utils.sh`
4. Get PR number from metadata
5. Call `get_pr_review_decision "<pr-number>"`
6. If status is NOT "APPROVED":
   - Stop and report: "Error: PR must be approved before completion"
   - Display current status (REVIEW_REQUIRED or CHANGES_REQUESTED)
   - Suggest: "Please get PR approval, then run /spec:complete again"
7. If status IS "APPROVED", ask user: "PR is approved. Merge PR now? (y/n)"
   - If yes: Call `merge_pr "<pr-number>"` to merge with squash and delete branches
   - If no: Skip merge but continue with completion
8. After merge (or skip), proceed with spec-completion-agent

**Spec Completion**:
Use the Task tool with subagent_type='spec-completion-agent' and this prompt:

"Complete spec: $1

Follow spec-completion-agent workflow:
- Validate score ≥90
- All tasks complete
- E2E tests passing (if applicable)
- Quality checks passing
- Update metadata (phase=complete)
- Create completion commit

Note: PR approval already verified and optionally merged."
