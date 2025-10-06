# Spec Commands

Namespaced slash commands for spec-driven development.

## Agent Flow

spec-requirements-generator → spec-design-generator → spec-task-generator

## Commands

### Full Workflow
- `/spec:init <feature>` - Initialize spec and generate all phases sequentially
- `/spec:complete <feature>` - **NEW!** Complete spec with validation, tests, and commit

### Individual Phases
- `/spec:requirements <feature>` - Generate requirements.md
- `/spec:design <feature>` - Generate design.md
- `/spec:tasks <feature>` - Generate tasks.md

### Quality & Sync
- `/spec:validate <feature>` - Validate spec quality
- `/spec:sync <feature>` - Update tasks based on code (Code → Spec)
- `/spec:refine <feature>` - Regenerate design + tasks from requirements (Spec → Code)

### Status
- `/spec:status [feature]` - Show spec status
- `/spec:list` - List all specs

## Example Workflow

```bash
# 1. Initialize new spec
/spec:init user-authentication

# 2. Implement tasks (TDD tracking via hooks)

# 3. Validate spec
/spec:validate user-authentication

# 4. Sync with code changes
/spec:sync user-authentication

# 5. Update requirements, then refine
# Edit specs/user-authentication/requirements.md
/spec:refine user-authentication

# 6. Complete spec (validation ≥90, tests pass, create commit)
/spec:complete user-authentication
```

## Scoping Best Practice

Create ONE cohesive spec per feature, not multiple micro-specs.

**Good**: `user-authentication` (login, signup, password reset, sessions)
**Bad**: `user-login` + `user-signup` + `password-reset` (should be ONE spec)
