# Spec Best Practices

## Core Principle: One Spec Per Feature/Module

Create **ONE cohesive spec** per feature or module, not multiple micro-specs.

### Why Single Spec Per Feature?

1. **Cohesion** - All related functionality documented together
2. **Traceability** - One source of truth for the feature
3. **Natural MVP boundaries** - 5-7 tasks fit one cohesive feature
4. **Matches implementation** - Features are built as cohesive units
5. **Prevents over-engineering** - No premature splitting

### Good Spec Scope (Feature-Level) ✅

These are **cohesive features** that deserve their own spec:

- ✅ **user-authentication** - login, signup, password reset, session management
- ✅ **payment-processing** - checkout, refunds, invoices, payment methods
- ✅ **notification-system** - email, SMS, push notifications, user preferences
- ✅ **search-functionality** - search bar, filters, results display, ranking
- ✅ **content-management** - create, edit, delete, publish, versioning

**Characteristics**:
- Solves a complete user need
- 5-7 implementation tasks
- 1-2 database tables
- 1-3 days development time

### Bad Spec Scope (Over-Split) ❌

These are **over-engineered splits** that should be ONE spec:

- ❌ `user-login` + `user-signup` + `password-reset` → Should be `user-authentication`
- ❌ `checkout` + `refunds` + `invoices` → Should be `payment-processing`
- ❌ `email-notifications` + `sms-notifications` → Should be `notification-system`
- ❌ `create-post` + `edit-post` + `delete-post` → Should be `content-management`

**Why this is bad**:
- Artificial boundaries that don't match user needs
- Harder to understand complete feature
- Forces duplicate design (auth patterns, database models, etc.)
- Violates DRY principle
- Unnecessary context switching

### Feature vs Task

**Feature** (gets a spec):
- User-facing capability
- Solves a complete problem
- Delivers value independently
- Example: "user-authentication"

**Task** (part of tasks.md in a spec):
- Implementation step
- Part of a larger feature
- Not valuable on its own
- Example: "Task 2: Login endpoint + validation"

### Example: User Authentication Feature

**ONE Spec**: `./specs/user-authentication/`

**requirements.md** - User stories:
- As a user, I want to sign up with email/password
- As a user, I want to log in with credentials
- As a user, I want to reset my password
- As a user, I want sessions to persist

**design.md** - Architecture:
- Database: User model with email, password_hash, session tokens
- API endpoints: /signup, /login, /logout, /reset-password
- Security: bcrypt, JWT tokens, rate limiting

**tasks.md** - Implementation:
- Task 1: Database schema + User model + tests
- Task 2: Signup endpoint + validation + tests
- Task 3: Login endpoint + JWT generation + tests
- Task 4: Password reset flow + email + tests
- Task 5: Session management + middleware + tests
- Task 6: E2E tests (full auth flow)

Total: **6 tasks, 1 table, ~20 hours** ✅ Perfect MVP scope

### What If Spec is Too Large?

If you can't fit in MVP constraints (>7 tasks, >2 tables, >24 hours):

**Option 1: Reduce Scope (Preferred) ✅**
- Cut features to core MVP
- Simplify design
- Remove nice-to-have functionality
- Goal: Get to 5-7 tasks

**Option 2: Split into Phases (Not Parallel Specs) ⚠️**
- Create `user-authentication-v1` (MVP: 5-7 tasks)
- Plan `user-authentication-v2` (enhancements after v1 ships)
- Ship v1, validate, then build v2

**NEVER: Split into Parallel Specs ❌**
- DON'T create `user-login` + `user-signup` as separate specs
- DON'T create parallel micro-specs that should be one feature

### What If Spec is Too Small?

If spec has <5 tasks:

**It's probably a task, not a feature**
- Should be part of a larger spec
- Example: "login endpoint" is a task in `user-authentication` spec

**Action**: Merge into larger feature spec

### Validation

Run `/spec validate <feature>` to check scope:
- ✅ 5-7 tasks: Appropriate feature-level scope
- ⚠️ <5 tasks: Too small, likely a task not a feature
- ⚠️ >7 tasks: Too large, reduce scope or split into phases

### Real-World Example

**Bad Approach** ❌ - Over-split into micro-specs:
```
./specs/user-login/          (3 tasks)
./specs/user-signup/         (3 tasks)
./specs/password-reset/      (2 tasks)
./specs/session-management/  (2 tasks)
```
Total: 4 specs, 10 tasks, fragmented documentation

**Good Approach** ✅ - One cohesive spec:
```
./specs/user-authentication/
  - requirements.md  (4 user stories)
  - design.md        (unified auth architecture)
  - tasks.md         (6 sequential tasks)
```
Total: 1 spec, 6 tasks, cohesive feature

### Summary

**Rule**: One spec = One feature = 5-7 tasks = 1-3 days

**When creating a spec, ask**:
1. Does this solve a complete user need? (Feature test)
2. Can I fit in 5-7 tasks? (MVP test)
3. Is this truly independent, or part of a larger feature? (Scope test)

If the answer is "yes, yes, yes" → Create the spec ✅
If any answer is "no" → Reconsider scope ❌

---

**Last updated**: 2025-10-05
**See also**:
- `${CLAUDE_DIR:-$HOME/.claude}/steering/product-principles.md` (MVP Obsession section)
- `/spec` command (scoping guidance in help text)
- `spec-comprehensive-validator` agent (automated scope validation)
