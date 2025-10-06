# Quick Start Guide

Get up and running with Claude Spec Framework in 5 minutes.

## Prerequisites

- Claude Code CLI installed
- Basic familiarity with TDD (Test-Driven Development)
- A project directory

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/claude-spec-framework/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/yourusername/claude-spec-framework.git
cd claude-spec-framework
./install.sh
```

## Your First Spec

### Step 1: Initialize

```bash
claude  # Start Claude Code in your project
/spec:init user-profile
```

This creates:
```
specs/user-profile/
├── requirements.md      # EARS format requirements
├── design.md           # Technical design
├── tasks.md            # TDD task breakdown
└── .spec-meta.json     # Metadata
```

### Step 2: Review Requirements

Check `specs/user-profile/requirements.md`:

```markdown
## User Stories

### US-1: View Profile
**Given** user is authenticated
**When** user navigates to profile page
**Then** system displays user's profile information
**And** profile shows name, email, and avatar
```

Edit as needed, then regenerate design:

```bash
/spec:refine user-profile
```

### Step 3: Implement with TDD

Open `specs/user-profile/tasks.md`:

```markdown
### Task 1: Create UserProfile Component
- Status: [ ] Not Started
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/components/UserProfile.tsx
  - src/components/UserProfile.spec.tsx
```

**Write the test first:**

```typescript
// src/components/UserProfile.spec.tsx
import { render, screen } from '@testing-library/react';
import UserProfile from './UserProfile';

describe('UserProfile', () => {
  it('displays user name', () => {
    render(<UserProfile name="John" email="john@example.com" />);
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

✅ Hook automatically marks: `[x] Tests written and failing (Red)`

**Implement the component:**

```typescript
// src/components/UserProfile.tsx
export default function UserProfile({ name, email }) {
  return (
    <div>
      <h1>{name}</h1>
      <p>{email}</p>
    </div>
  );
}
```

✅ Hook automatically marks:
- `[x] Implementation complete`
- `[x] Tests passing (Green)`
- `Status: [x] Completed`

### Step 4: Validate

```bash
/spec:validate user-profile
```

Output:
```
✅ Requirements: 3 user stories, all EARS compliant
✅ Design: Complete with architecture and data models
✅ Tasks: 5 tasks, 5 completed (100%)
✅ Requirements mapping: All criteria tested
```

### Step 5: Check Status

```bash
/spec:status user-profile
```

Output:
```
📊 Spec: user-profile
Phase: completed
Progress: 5/5 tasks (100%)
Last updated: 2025-10-06

✅ All tasks completed
✅ All requirements validated
```

## Understanding the Workflow

### 1. **Requirements Phase** (`/spec:requirements`)
- Uses EARS format (Event-Action-Response-State)
- Generates user stories with acceptance criteria
- Focus: **WHAT** the feature does

### 2. **Design Phase** (`/spec:design`)
- Technical architecture
- Data models & API contracts
- Focus: **HOW** to implement

### 3. **Tasks Phase** (`/spec:tasks`)
- Sequential implementation tasks (5-7 tasks)
- TDD approach with Red-Green-Refactor
- Focus: **DO** the implementation

### 4. **Implementation** (manual)
- Follow TDD cycle
- Hooks auto-track progress
- Focus: **BUILD** with tests

### 5. **Validation** (`/spec:validate`)
- Quality checks
- Requirements mapping
- Focus: **VERIFY** completeness

## Hook Automation

Hooks work **automatically** after file changes:

### TDD Tracking Hook
```bash
# You write test file → Hook detects
→ Marks: [x] Tests written and failing (Red)

# You implement → Tests pass → Hook detects
→ Marks: [x] Implementation complete
→ Marks: [x] Tests passing (Green)
→ Status: [x] Completed
```

### Metadata Sync Hook
```bash
# Any file change → Hook updates
→ Updates .spec-meta.json with timestamp
→ Tracks modified files
```

### Requirements Validation Hook
```bash
# Task completes → Hook validates
→ Checks EARS criteria are tested
→ Reports unvalidated requirements
```

## Common Workflows

### Starting a New Feature

```bash
/spec:init feature-name
# Review requirements
# Edit specs/feature-name/requirements.md if needed
/spec:refine feature-name
# Implement tasks
/spec:validate feature-name
```

### Updating Requirements Mid-Implementation

```bash
# Edit specs/feature-name/requirements.md
/spec:refine feature-name  # Regenerates design + tasks
# Continue implementation
```

### Checking Progress

```bash
/spec:status feature-name  # Single spec
/spec:list                 # All specs
```

### Syncing After Manual Code Changes

```bash
/spec:sync feature-name
# Updates tasks based on code changes
```

## Tips for Success

1. **Scope properly** - One cohesive feature per spec, not micro-specs
   - ✅ Good: `user-authentication` (login, signup, password reset)
   - ❌ Bad: `user-login`, `user-signup`, `password-reset` (3 separate specs)

2. **Trust the hooks** - They auto-track TDD progress, no manual updates needed

3. **Validate early** - Run `/spec:validate` before creating PRs

4. **Refine iteratively** - Edit requirements, run `/spec:refine`, repeat

5. **Follow TDD strictly** - Write tests first, hooks track the cycle

## Troubleshooting

### Hooks not triggering?

Check settings:
```bash
cat ~/.claude/settings.json | jq '.hooks'
```

Should show hook commands pointing to `~/.claude/hooks/`.

### Tasks not auto-completing?

Ensure:
1. Spec phase is `implementation` (check `.spec-meta.json`)
2. Test files exist (`.spec.ts`, `.test.ts`)
3. Tests pass (run `npm test`)

### Want to disable specific hooks?

Create `~/.claude/spec-framework.config.json`:
```json
{
  "hooks": {
    "disabled": ["nx-quality"]
  }
}
```

## Next Steps

- Read [Spec Best Practices](spec-best-practices.md)
- Understand [Hook System](hooks-guide.md)
- Explore [Examples](examples/)
- Learn [Customization](customization.md)

---

**Questions?** Open an issue or discussion on GitHub!
