---
allowed-tools: Bash(git:*), Bash(source:*), Read, Write
description: Create GitHub PR for spec implementation
argument-hint: <feature-name>
---

Create GitHub PR for spec: **$1**

**Prerequisites Check**:
1. Verify ./specs/$1/.spec-meta.json exists using Read tool - if not, stop and report error "Spec not found. Run /spec:init first"
2. Check for uncommitted changes - if any exist, stop and report error "Please commit all changes before creating PR"

**PR Creation Steps**:

1. **Source utilities**:
   - `source ./scripts/utils/git-utils.sh`
   - `source ./scripts/utils/gh-utils.sh`

2. **Read spec metadata**:
   - Read ./specs/$1/.spec-meta.json to get feature name and branch name
   - Verify we're on the correct branch (branchName from metadata)

3. **Push branch to remote**:
   - Use Bash: `git push -u origin spec/$1`
   - If push fails, stop and report error with git output

4. **Generate PR body from template**:
   - Read ./scripts/utils/pr-template.md
   - Replace {{FEATURE_NAME}} with $1 in the template content
   - Store result in variable for PR creation

5. **Create PR using gh-utils**:
   - Call `check_gh_auth` - if fails, stop and report error
   - Set PR title: `[Spec] $1`
   - Call `create_pr "$1" "[Spec] $1" "<pr-body-from-template>"`
   - Capture PR URL from output

6. **Update metadata**:
   - Read current ./specs/$1/.spec-meta.json
   - Add/update fields:
     - `prUrl`: URL returned from create_pr
     - `prNumber`: Extract number from URL (last segment after /pull/)
     - `prStatus`: null
     - `prCreatedAt`: current timestamp
     - `prUpdatedAt`: current timestamp
     - `phase`: "in-review"
   - Write updated JSON back to ./specs/$1/.spec-meta.json

7. **Report success**:
   - Display PR URL
   - Display next steps: "PR created successfully! Next: Get review approval, then run /spec:complete"

**Error Handling**:
- If branch doesn't exist: "Error: Branch spec/$1 not found. Run /spec:init first"
- If gh CLI not authenticated: "Error: GitHub CLI not authenticated. Run: gh auth login"
- If PR already exists: "PR already exists at <URL>. Metadata updated."
- If any step fails: Report clear error with remediation steps
