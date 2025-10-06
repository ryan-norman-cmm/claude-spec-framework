# Example: Simple API Endpoint

This example demonstrates a complete spec for a simple REST API endpoint.

## Scenario

Create a GET endpoint to retrieve user information by ID.

## Spec Structure

```
simple-api-endpoint/
├── requirements.md      # EARS format requirements
├── design.md           # Technical design
├── tasks.md            # TDD task breakdown
├── .spec-meta.json     # Metadata
└── README.md           # This file
```

## What This Example Shows

### ✅ EARS Requirements Format
- Event-Action-Response-State structure
- Clear acceptance criteria
- Non-functional requirements

### ✅ Technical Design
- API architecture (Controller → Service → Repository)
- Data models and DTOs
- API contract with examples
- Error handling

### ✅ TDD Task Breakdown
- 7 sequential tasks
- Red-Green-Refactor checkboxes
- File lists for each task
- Dependencies between tasks

### ✅ Spec Metadata
- Phase tracking
- Task progress
- Tags and categorization

## How to Use This Example

### 1. Study the Structure

```bash
# Read requirements first
cat requirements.md

# Review the design
cat design.md

# Understand task breakdown
cat tasks.md
```

### 2. Initialize Your Own Spec

```bash
/spec:init get-product-by-id

# Edit requirements
# Edit specs/get-product-by-id/requirements.md

# Regenerate design
/spec:refine get-product-by-id
```

### 3. Implement with TDD

Follow the task order:
1. Create DTOs (Task 1)
2. Create Repository (Task 2)
3. Create Service (Task 3)
4. Create Controller (Task 4)
5. Add Integration Tests (Task 5)
6. Add Validation (Task 6)
7. Update Docs (Task 7)

Hooks will auto-track your progress!

## Key Learnings

### EARS Format Benefits
- Unambiguous requirements
- Testable criteria
- Clear state transitions

### Layered Architecture
- Separation of concerns
- Testable components
- Maintainable code

### TDD Workflow
- Write test first (Red)
- Implement minimal code (Green)
- Refactor while green (Refactor)
- Hooks track automatically!

## Customization Ideas

Adapt this pattern for:
- POST /api/users (create user)
- PUT /api/users/:id (update user)
- DELETE /api/users/:id (delete user)
- GET /api/users (list users with pagination)

## Related Examples

- [Authentication Feature](../authentication-feature/) - More complex, multi-endpoint feature
- [CRUD Operations](../crud-operations/) - Full CRUD spec

---

**Try it yourself:** `/spec:init my-api-endpoint`
