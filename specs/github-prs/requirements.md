# Requirements Specification

## Feature Overview
**Feature Name:** GitHub PR Integration
**Description:** Integrate GitHub CLI (gh) to create PRs per spec and ensure they are reviewed and approved before marking the spec as complete. This enforces code review as part of the spec completion workflow.
**Priority:** High

## User Stories

### Story 1: Automatic Branch Creation on Spec Initialization
**As a** developer using the spec framework
**I want** a new git branch automatically created when I initialize a spec
**So that** my work is isolated from main and ready for PR submission

#### Acceptance Criteria (EARS Format)
- **Given** I am on the main branch with a clean working directory
- **When** I initialize a new spec using `/spec:init [feature-name]`
- **Then** a new branch named `spec/[feature-name]` is created from main
- **And** I am automatically checked out to the new branch
- **And** the branch name is stored in `.spec-meta.json`

#### Edge Cases
- **Given** I am not on the main branch
- **When** I attempt to initialize a spec
- **Then** I receive an error message: "Must be on main branch to initialize spec"
- **And** the spec initialization is blocked

- **Given** I have uncommitted changes in my working directory
- **When** I attempt to initialize a spec
- **Then** I receive an error message: "Working directory must be clean"
- **And** the spec initialization is blocked

- **Given** a branch `spec/[feature-name]` already exists
- **When** I initialize a spec with the same feature name
- **Then** I receive an error asking if I want to use the existing branch or choose a different name

### Story 2: PR Creation After Implementation
**As a** developer who has completed a spec implementation
**I want** to create a GitHub PR directly from the spec framework
**So that** my changes can be reviewed without manual PR creation

#### Acceptance Criteria (EARS Format)
- **Given** I am on a spec branch with committed changes
- **When** I run `/spec:create-pr` command
- **Then** all local changes are pushed to the remote branch
- **And** a GitHub PR is created using `gh pr create` with:
  - Base branch: main
  - Head branch: current spec branch
  - Title: "[Spec] [feature-name]"
  - Body: Link to requirements.md and technical design
- **And** the PR URL is stored in `.spec-meta.json` under `prUrl` field
- **And** the phase is updated to "in-review"

#### Edge Cases
- **Given** I have uncommitted changes
- **When** I run `/spec:create-pr`
- **Then** I receive an error: "Commit all changes before creating PR"

- **Given** the GitHub CLI is not authenticated
- **When** I run `/spec:create-pr`
- **Then** I receive an error: "GitHub CLI not authenticated. Run: gh auth login"

- **Given** a PR already exists for the current branch
- **When** I run `/spec:create-pr`
- **Then** I receive the existing PR URL
- **And** no duplicate PR is created

### Story 3: PR Approval Status Check
**As a** developer ready to complete a spec
**I want** the framework to verify my PR is approved
**So that** code review is enforced before marking the spec complete

#### Acceptance Criteria (EARS Format)
- **Given** a PR exists for the current spec (prUrl in .spec-meta.json)
- **When** I run `/spec:complete` command
- **Then** the framework checks PR approval status using `gh pr view [pr-url] --json reviewDecision`
- **And** if reviewDecision is "APPROVED", the spec completion proceeds
- **And** if reviewDecision is not "APPROVED", the spec completion is blocked
- **And** I receive a message: "PR must be approved before completing spec. Current status: [status]"

#### Review Status Logic
- **Given** the PR has no reviews
- **When** I check completion status
- **Then** I see: "PR has no reviews yet. Request a review from your team."

- **Given** the PR has "CHANGES_REQUESTED" status
- **When** I check completion status
- **Then** I see: "PR has changes requested. Address feedback and request re-review."

- **Given** the PR is approved but has merge conflicts
- **When** I check completion status
- **Then** I see: "PR is approved but has merge conflicts. Resolve conflicts first."

### Story 4: PR Status Visibility
**As a** developer working on a spec
**I want** to see my PR status at any time
**So that** I know what actions are needed to complete the spec

#### Acceptance Criteria (EARS Format)
- **Given** a PR exists for the current spec
- **When** I run `/spec:status` command
- **Then** I see the PR URL, approval status, and any blocking issues
- **And** I see a list of reviewers and their review states
- **And** I see if the PR is mergeable (no conflicts)

#### Status Display Format
```
Spec: github-prs
Phase: in-review
PR: https://github.com/user/repo/pull/123
Status: Awaiting review
Reviewers:
  - @reviewer1: Review pending
  - @reviewer2: Approved
Mergeable: Yes
Next action: Request review from @reviewer1
```

### Story 5: Merge PR on Spec Completion
**As a** developer whose PR is approved
**I want** the option to merge my PR when completing the spec
**So that** my changes are integrated into main automatically

#### Acceptance Criteria (EARS Format)
- **Given** my PR is approved and has no conflicts
- **When** I run `/spec:complete` command
- **Then** I am prompted: "PR is approved. Merge now? (y/n)"
- **And** if I select "y", the PR is merged using `gh pr merge --squash`
- **And** if I select "n", the spec is marked complete but PR remains open
- **And** the phase is updated to "complete"
- **And** I am checked out back to main branch
- **And** the main branch is pulled to get latest changes

#### Post-Merge Cleanup
- **Given** the PR has been merged successfully
- **When** the merge completes
- **Then** the local spec branch is deleted
- **And** the remote spec branch is deleted
- **And** a success message displays: "Spec complete. Branch merged and cleaned up."

## Business Rules
- **BR1:** All specs must be developed on a dedicated branch following the pattern `spec/[feature-name]`
- **BR2:** PR approval is mandatory before marking a spec as complete (cannot be bypassed)
- **BR3:** Spec initialization requires a clean working directory on the main branch
- **BR4:** PR creation requires all changes to be committed
- **BR5:** Only squash merges are allowed to maintain clean commit history
- **BR6:** Branch cleanup (deletion) only occurs after successful merge

## Non-Functional Requirements
- **Performance:** PR status checks should complete within 3 seconds
- **Security:** Use GitHub CLI authentication (no hardcoded tokens)
- **Reliability:** Handle GitHub API rate limits gracefully with clear error messages
- **Usability:** All error messages must include actionable next steps
- **Compatibility:** Must work with GitHub CLI v2.0+ and git v2.30+

## Testing Requirements

### E2E Tests
Test scenarios using Cucumber + Playwright (where applicable) or shell integration tests:

1. **Happy Path: Complete Spec Workflow**
   - Initialize spec -> create branch
   - Make changes and commit
   - Create PR
   - Approve PR (simulate with gh CLI)
   - Complete spec with merge
   - Verify branch cleanup

2. **PR Blocking Scenarios**
   - Attempt spec completion with unapproved PR
   - Attempt spec completion with changes requested
   - Attempt spec completion with merge conflicts

3. **Error Handling**
   - Initialize spec with dirty working directory
   - Initialize spec from non-main branch
   - Create PR without GitHub CLI authentication
   - Create duplicate PR

4. **PR Status Visibility**
   - Check status with no PR
   - Check status with pending reviews
   - Check status with mixed review states

### Test Environment
- Real git repository with multiple branches
- GitHub CLI authenticated with test repository
- Ability to simulate PR reviews (test GitHub account or mock)

### Test Data
- Test repository with main branch
- Sample spec directories with .spec-meta.json files
- Mock PR responses for various approval states

## Dependencies
- **GitHub CLI (gh):** Version 2.0 or higher must be installed and authenticated
- **Git:** Version 2.30 or higher for branch management
- **Existing Spec Framework:** Relies on `/spec:init`, `/spec:complete`, `/spec:status` commands
- **Node.js/TypeScript:** For command execution and JSON parsing
- **.spec-meta.json format:** Must support new fields: `branchName`, `prUrl`, `prStatus`

## Out of Scope
- **Auto-merge without prompt:** User must explicitly confirm merge action
- **Multiple PR support per spec:** One spec = one PR only
- **PR template customization:** Uses default PR template for MVP
- **Reviewer assignment automation:** User must manually request reviewers via GitHub UI
- **Draft PR support:** Only ready-for-review PRs are supported
- **Rebase or merge commit strategies:** Only squash merge supported initially
- **Integration with other Git platforms:** GitHub only (no GitLab, Bitbucket)
- **PR comment management:** No framework-driven PR comments or bot integration
- **CI/CD status checks:** Framework does not wait for CI/CD pipelines (only approval status)

## Success Metrics
- **Adoption:** 100% of specs use PR workflow within 2 weeks of feature launch
- **Code Review Compliance:** 0% of specs marked complete without PR approval
- **Time Efficiency:** Average time from implementation to PR creation < 30 seconds
- **Error Rate:** < 5% of PR creation attempts fail due to framework errors
- **User Satisfaction:** Developers report PR workflow as "seamless" in feedback survey
