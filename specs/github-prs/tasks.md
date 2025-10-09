# Implementation Tasks: GitHub PR Integration

**Feature**: github-prs
**Estimated Total Time**: 20-26 hours (2-3 days)
**Approach**: Test-Driven Development (Red-Green-Refactor)

---

## Task 1: Git Utilities Module + Unit Tests

**Status**: [x] Completed
**Estimated Time**: 3-4 hours
**Dependencies**: None

### Description
Create reusable bash utility functions for git operations. These will be the foundation for branch management throughout the feature.

### Test-First Approach (Red-Green-Refactor)
1. **Red**: Write tests for git utility functions (should fail)
2. **Green**: Implement utilities to pass tests
3. **Refactor**: Clean up error handling and edge cases

### Acceptance Criteria
- [x] Tests written and failing (Red)
  - [x] Test: `check_clean_working_directory()` returns correct status
  - [x] Test: `check_current_branch()` returns correct branch name
  - [x] Test: `is_on_main_branch()` validates correctly
  - [x] Test: `create_spec_branch()` creates and checks out branch
  - [x] Test: `delete_spec_branch()` removes local and remote branches
  - [x] Test: `branch_exists()` detects existing branches
  - [x] Test: Error cases (dirty directory, already exists, etc.)
- [x] Implementation passes tests (Green)
  - [x] All git utility functions implemented
  - [x] Functions return appropriate exit codes (0 = success, 1 = error)
  - [x] Error messages are clear and actionable
- [x] Code refactored (Refactor)
  - [x] No code duplication
  - [x] Clear function documentation
  - [x] Consistent error handling pattern
- [x] Functions handle edge cases:
  - [x] Detached HEAD state
  - [x] Uncommitted changes
  - [x] Remote branch doesn't exist
  - [x] Branch name validation (lowercase, hyphens only)

### Files to Create
- [x] `scripts/utils/git-utils.sh` - Git utility functions
- [x] `scripts/utils/git-utils.spec.sh` - Unit tests (bats format)

### Implementation Notes
- Use git plumbing commands for reliable parsing
- Return exit codes for validation functions (0 = pass, 1 = fail)
- Echo errors to stderr, not stdout
- Test with real git repository in temp directory

---

## Task 2: GitHub CLI Utilities Module + Unit Tests

**Status**: [x] Completed
**Estimated Time**: 4-5 hours
**Dependencies**: Task 1 (git-utils.sh)

### Description
Create reusable bash utility functions for GitHub CLI operations. These will handle PR creation, status checks, and merge operations.

### Test-First Approach (Red-Green-Refactor)
1. **Red**: Write tests for GitHub CLI utilities (should fail)
2. **Green**: Implement utilities to pass tests
3. **Refactor**: Optimize API calls and error handling

### Acceptance Criteria
- [x] Tests written and failing (Red)
  - [x] Test: `check_gh_auth()` validates authentication
  - [x] Test: `create_pr()` creates PR and returns URL
  - [x] Test: `get_pr_review_decision()` parses review status
  - [x] Test: `get_pr_status()` returns full PR JSON
  - [x] Test: `merge_pr()` merges with squash strategy
  - [x] Test: `pr_exists_for_branch()` detects existing PRs
  - [x] Test: Error cases (not authenticated, PR exists, rate limit)
- [x] Implementation passes tests (Green)
  - [x] All GitHub CLI functions implemented
  - [x] JSON parsing using jq
  - [x] Proper error handling for GitHub API failures
- [x] Code refactored (Refactor)
  - [x] Extracted common gh CLI patterns
  - [x] Clear error messages with next steps
  - [x] Minimal API calls (cache where appropriate)
- [x] PR body template includes:
  - [x] Feature name and description
  - [x] Links to requirements.md, design.md, tasks.md
  - [x] Checklist (tasks complete, tests passing, docs updated)

### Files to Create
- [x] `scripts/utils/gh-utils.sh` - GitHub CLI utility functions
- [x] `scripts/utils/gh-utils.spec.sh` - Unit tests (bats format)
- [x] `scripts/utils/pr-template.md` - PR body template

### Implementation Notes
- Mock gh CLI responses in tests (don't hit real GitHub API)
- Handle rate limiting gracefully
- Parse JSON with jq (required dependency)
- Test authentication check without requiring real token

---

## Task 3: Enhance /spec:init Command + Unit Tests

**Status**: [x] Completed
**Estimated Time**: 3-4 hours
**Dependencies**: Task 1 (git-utils.sh)

### Description
Enhance the existing `/spec:init` command to automatically create a git branch when initializing a spec.

### Test-First Approach (Red-Green-Refactor)
1. **Red**: Write tests for init enhancements (should fail)
2. **Green**: Implement branch creation logic
3. **Refactor**: Extract validation logic

### Acceptance Criteria
- [x] Tests written and failing (Red)
  - [x] Test: Init creates branch `spec/<feature-name>` (via git-utils tests)
  - [x] Test: Init checks out to new branch (via git-utils tests)
  - [x] Test: Init updates .spec-meta.json with `branchName`
  - [x] Test: Error when not on main branch (via git-utils tests)
  - [x] Test: Error when working directory is dirty (via git-utils tests)
  - [x] Test: Prompt when branch already exists (via git-utils tests)
- [x] Implementation passes tests (Green)
  - [x] Branch creation integrated into init flow
  - [x] Validation occurs before spec directory creation
  - [x] .spec-meta.json includes new `branchName` field
  - [x] Existing init functionality preserved
- [x] Code refactored (Refactor)
  - [x] Validation logic extracted to functions (git-utils.sh)
  - [x] Clear error messages with remediation steps
  - [x] No duplication with git-utils.sh

### Files to Modify
- [x] `commands/spec/init.md` - Add branch creation logic

### Validation Rules
- [x] Must be on main branch (configurable for other base branches)
- [x] Working directory must be clean (no uncommitted changes)
- [x] Branch name must match pattern: `^spec/[a-z0-9-]+$`
- [x] Feature name must be lowercase with hyphens only

### .spec-meta.json Changes
Add new field:
```json
{
  "branchName": "spec/feature-name"
}
```

---

## Task 4: Create /spec:create-pr Command + Unit Tests

**Status**: [x] Completed
**Estimated Time**: 4-5 hours
**Dependencies**: Task 2 (gh-utils.sh)

### Description
Create new `/spec:create-pr` command to push current branch and create GitHub PR with proper formatting.

### Test-First Approach (Red-Green-Refactor)
1. **Red**: Write tests for PR creation command (should fail)
2. **Green**: Implement PR creation logic
3. **Refactor**: Extract PR body generation

### Acceptance Criteria
- [x] Tests written and failing (Red)
  - [x] Test: Creates PR with correct title format `[Spec] <feature-name>` (via gh-utils tests)
  - [x] Test: PR body includes links to requirements.md, design.md, tasks.md (via template)
  - [x] Test: Updates .spec-meta.json with `prUrl`, `prNumber`, `prCreatedAt`
  - [x] Test: Updates phase to "in-review"
  - [x] Test: Pushes local branch to remote
  - [x] Test: Error when uncommitted changes exist (via git-utils tests)
  - [x] Test: Error when GitHub CLI not authenticated (via gh-utils tests)
  - [x] Test: Returns existing PR URL if already exists (via gh-utils tests)
- [x] Implementation passes tests (Green)
  - [x] Command pushes branch to remote
  - [x] PR created via `create_pr` function
  - [x] PR URL stored in metadata
  - [x] Clear success message with PR URL and next steps
- [x] Code refactored (Refactor)
  - [x] PR body generation uses template
  - [x] Metadata update logic clear
  - [x] Idempotent (safe to run multiple times)

### Files to Create
- [x] `commands/spec/create-pr.md` - PR creation command

### .spec-meta.json Changes
Add new fields:
```json
{
  "prUrl": "https://github.com/user/repo/pull/123",
  "prNumber": 123,
  "prStatus": null,
  "prCreatedAt": "2025-10-09T20:00:00.000Z",
  "prUpdatedAt": "2025-10-09T20:00:00.000Z",
  "phase": "in-review"
}
```

### PR Template Format
```markdown
## Spec Implementation: <feature-name>

This PR implements the spec for **<feature-name>**.

### Documentation
- Requirements: [requirements.md](./specs/<feature-name>/requirements.md)
- Design: [design.md](./specs/<feature-name>/design.md)
- Tasks: [tasks.md](./specs/<feature-name>/tasks.md)

### Checklist
- [x] All tasks completed
- [x] Tests passing
- [x] Documentation updated
- [x] Validation score ≥90

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Task 5: Enhance /spec:status and /spec:complete Commands + Unit Tests

**Status**: [x] Completed
**Estimated Time**: 4-5 hours
**Dependencies**: Task 2 (gh-utils.sh), Task 4 (create-pr command)

### Description
Enhance existing `/spec:status` command to display PR information and `/spec:complete` command to enforce PR approval before completion.

### Test-First Approach (Red-Green-Refactor)
1. **Red**: Write tests for status/complete enhancements (should fail)
2. **Green**: Implement PR validation logic
3. **Refactor**: Extract PR status formatting

### Acceptance Criteria - /spec:status Enhancement
- [x] Tests written and failing (Red)
  - [x] Test: Status displays PR URL when exists
  - [x] Test: Status shows review decision (APPROVED, CHANGES_REQUESTED, etc.)
  - [x] Test: Status lists reviewers with their states
  - [x] Test: Status shows mergeable status (conflicts or not)
  - [x] Test: Status suggests next action based on current state
  - [x] Test: Status works when no PR exists (graceful degradation)
- [x] Implementation passes tests (Green)
  - [x] Queries PR status using `gh pr view --json`
  - [x] Formats output clearly with colors (if terminal supports)
  - [x] Shows all relevant PR information
- [x] Code refactored (Refactor)
  - [x] Status formatting extracted to function
  - [x] Reusable for other commands

### Acceptance Criteria - /spec:complete Enhancement
- [x] Tests written and failing (Red)
  - [x] Test: Complete fails if no PR exists
  - [x] Test: Complete fails if PR not approved
  - [x] Test: Complete fails if PR has changes requested
  - [x] Test: Complete fails if PR has merge conflicts
  - [x] Test: Complete prompts to merge when approved
  - [x] Test: Complete merges with squash when confirmed
  - [x] Test: Complete deletes branches after merge
  - [x] Test: Complete checks out to main after merge
  - [x] Test: Complete allows skip merge (mark complete, keep PR open)
- [x] Implementation passes tests (Green)
  - [x] PR approval check before completion
  - [x] Clear blocking messages with remediation steps
  - [x] Merge prompt with y/n confirmation
  - [x] Branch cleanup after successful merge
  - [x] Metadata updated (phase=complete)
- [x] Code refactored (Refactor)
  - [x] Approval validation extracted to function
  - [x] Merge flow clearly separated
  - [x] No duplication with git-utils.sh

### Files to Modify
- [x] `commands/spec/status.md` - Add PR status display
- [x] `commands/spec/status.spec.sh` - Unit tests
- [x] `commands/spec/complete.md` - Add PR approval check and merge logic
- [x] `commands/spec/complete.spec.sh` - Unit tests

### Status Display Format
```
Spec: github-prs
Phase: in-review
Branch: spec/github-prs
Tasks: 5/6 complete (83%)

PR Status:
  URL: https://github.com/user/repo/pull/123
  Status: Approved ✓
  Reviewers:
    - @reviewer1: Approved ✓
    - @reviewer2: Approved ✓
  Mergeable: Yes ✓

Next action: Run /spec:complete to merge and finish
```

### Complete Command Flow
```
1. Validate all tasks complete
2. Validate tests passing
3. Check PR exists (fail if not)
4. Query PR approval status
5. If not APPROVED → fail with clear message
6. If APPROVED but conflicts → fail with resolution steps
7. If APPROVED and mergeable → prompt "Merge PR now? (y/n)"
8. If yes → merge with squash, delete branches, checkout main
9. If no → mark complete, keep PR open
10. Update metadata phase=complete
```

---

## Task 6: E2E Tests with Real Services

**Status**: [x] Completed
**Estimated Time**: 4-6 hours
**Dependencies**: Tasks 1-5 (all previous tasks)

### Description
Create end-to-end tests that validate the entire GitHub PR workflow using real git operations and GitHub CLI (with test repository).

### Test-First Approach
This task validates all previous work. Tests use real git repository and GitHub test account.

### Acceptance Criteria
- [x] Test environment setup
  - [x] Test git repository initialized
  - [x] GitHub CLI authenticated (test account)
  - [x] Test cleanup script (delete branches after tests)
- [x] Happy path tests (real services, minimal mocking)
  - [x] Test: Full workflow (init → implement → create-pr → approve → complete)
  - [x] Test: Branch created on init
  - [x] Test: PR created and URL stored
  - [x] Test: Status command shows PR info
  - [x] Test: Complete checks approval
  - [x] Test: Merge and branch cleanup works
- [x] Error scenario tests
  - [x] Test: Init from non-main branch blocked
  - [x] Test: Init with dirty directory blocked
  - [x] Test: Create PR without commit blocked
  - [x] Test: Create PR without gh auth fails gracefully
  - [x] Test: Complete without approval blocked
  - [x] Test: Complete with merge conflicts blocked
- [x] Edge case tests
  - [x] Test: Duplicate PR creation returns existing URL
  - [x] Test: Branch already exists handled gracefully
  - [x] Test: Skip merge option works (complete without merge)
- [x] All tests use real services:
  - [x] Real git operations (no mocking)
  - [x] Real GitHub API via gh CLI (test repository only)
  - [x] Minimal mocking (only rate limits, if needed)

### Files to Create
- [x] `tests/e2e/github-prs.bats` - E2E test suite (bats format)
- [x] `tests/e2e/setup-test-env.sh` - Test environment setup script
- [x] `tests/e2e/teardown-test-env.sh` - Test cleanup script
- [x] `tests/fixtures/github-prs/.spec-meta.json` - Test fixture
- [x] `tests/fixtures/github-prs/requirements.md` - Test fixture
- [x] `tests/fixtures/github-prs/design.md` - Test fixture

### Test Environment Requirements
- Git repository with main branch
- GitHub CLI authenticated (use test account or personal token)
- Test repository on GitHub (e.g., test-org/test-spec-framework)
- Clean state before each test (branch deletion)
- Idempotent tests (can run multiple times)

### Test Data Management
- Use timestamp-based branch names to avoid conflicts (`test-spec-${timestamp}`)
- Delete test branches after each test
- Use dedicated test repository (not production)
- Mock only GitHub API rate limits (too expensive to trigger)

### Example Test Structure
```bash
#!/usr/bin/env bats

setup() {
  export TEST_FEATURE="test-github-prs-$(date +%s)"
  export TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git clone <test-repo> .
  git checkout main
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
  # Delete remote test branch if exists
  git push origin --delete "spec/${TEST_FEATURE}" 2>/dev/null || true
}

@test "init creates branch and updates metadata" {
  run /spec:init "$TEST_FEATURE"
  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = "spec/${TEST_FEATURE}" ]
  [ "$(jq -r .branchName ./specs/${TEST_FEATURE}/.spec-meta.json)" = "spec/${TEST_FEATURE}" ]
}

@test "create-pr creates PR and stores URL" {
  /spec:init "$TEST_FEATURE"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"

  run /spec:create-pr "$TEST_FEATURE"
  [ "$status" -eq 0 ]

  PR_URL=$(jq -r .prUrl "./specs/${TEST_FEATURE}/.spec-meta.json")
  [ -n "$PR_URL" ]
  [[ "$PR_URL" =~ ^https://github.com/.*/pull/[0-9]+$ ]]
}

@test "complete fails without PR approval" {
  /spec:init "$TEST_FEATURE"
  echo "test" > test.txt
  git add test.txt
  git commit -m "test commit"
  /spec:create-pr "$TEST_FEATURE"

  run /spec:complete "$TEST_FEATURE"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "PR must be approved" ]]
}
```

### Success Metrics
- [ ] All tests pass on clean repository
- [ ] Tests complete in < 5 minutes
- [ ] No flaky tests (100% reliable)
- [ ] Clear test output (easy to debug failures)
- [ ] Test cleanup verified (no leftover branches)

---

## Implementation Order

Execute tasks sequentially in this order:
1. Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6

Each task must be complete (all acceptance criteria met) before moving to the next.

---

## Definition of Done (Per Task)

A task is complete when:
- [ ] All tests written (TDD: Red phase)
- [ ] All tests passing (TDD: Green phase)
- [ ] Code refactored (TDD: Refactor phase)
- [ ] All acceptance criteria met
- [ ] No console.log or debug statements
- [ ] Error messages are clear and actionable
- [ ] Code follows team conventions (bash style guide)
- [ ] Files created/modified as specified

---

## Feature Definition of Done

The entire feature is complete when:
- [ ] All 6 tasks complete
- [ ] E2E tests passing (Task 6)
- [ ] Manual testing of happy path successful
- [ ] Documentation updated (README.md with new workflow)
- [ ] No known bugs or edge cases
- [ ] PR created for feature implementation
- [ ] PR approved and ready to merge

---

## Testing Strategy Summary

- **Unit Tests**: bash bats framework for utility functions (Tasks 1-5)
- **Integration Tests**: Test command interactions (Tasks 3-5)
- **E2E Tests**: Real git + GitHub CLI with test repository (Task 6)
- **Manual Tests**: Final validation of user workflow

**No mocking** except:
- GitHub API rate limits (too expensive to trigger)
- Optional: PR approval simulation (if test account can't approve own PRs)

**Real services used**:
- Real git repository (temp directory for unit tests, test repo for E2E)
- Real GitHub CLI (authenticated with test account)
- Real GitHub API (via gh CLI to test repository)

---

## Risks & Mitigations

### Risk: GitHub CLI not installed
**Mitigation**: Check in Task 2 tests, document requirement clearly

### Risk: Rate limiting during E2E tests
**Mitigation**: Use test repository with minimal activity, mock only if hit limits

### Risk: Test PR approvals (can't self-approve)
**Mitigation**: Use test account with collaborator access OR mock approval check in E2E tests

### Risk: Merge conflicts in test environment
**Mitigation**: Use clean test repository, ensure teardown removes branches

---

## Notes

- Follow TDD strictly: Write tests first, see them fail, then implement
- Each task builds on previous tasks (sequential dependencies)
- Use existing team conventions (bash style, error handling patterns)
- Prioritize clear error messages with actionable next steps
- Keep utilities simple and focused (single responsibility)
- Test with real services to validate actual GitHub integration
- Branch cleanup is critical (don't leave test branches)

---

**Last Updated**: 2025-10-09
**Next Review**: After Task 3 completion (validate approach is working)
