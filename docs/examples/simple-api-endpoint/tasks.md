# Tasks: Get User by ID API

## Task 1: Create User DTO
- Status: [ ] Not Started
- Estimated Time: 0.5 hours
- Dependencies: None
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/api/users/dto/user.dto.ts
  - src/api/users/dto/user.dto.spec.ts

**TDD Notes:**
- Test DTO shape matches requirements (id, name, email, createdAt)
- Test date serialization to ISO 8601

## Task 2: Create Users Repository
- Status: [ ] Not Started
- Estimated Time: 1 hour
- Dependencies: Task 1
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/api/users/users.repository.ts
  - src/api/users/users.repository.spec.ts

**TDD Notes:**
- Test findById returns user when exists
- Test findById returns null when not exists
- Mock database connection

## Task 3: Create Users Service
- Status: [ ] Not Started
- Estimated Time: 1 hour
- Dependencies: Task 2
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/api/users/users.service.ts
  - src/api/users/users.service.spec.ts

**TDD Notes:**
- Test service calls repository
- Test service returns user or null
- Mock repository dependency

## Task 4: Create Users Controller
- Status: [ ] Not Started
- Estimated Time: 1.5 hours
- Dependencies: Task 3
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/api/users/users.controller.ts
  - src/api/users/users.controller.spec.ts

**TDD Notes:**
- Test GET /api/users/:id returns 200 with user DTO
- Test returns 404 when user not found
- Test returns 400 for invalid UUID
- Mock service dependency

## Task 5: Add Integration Tests
- Status: [ ] Not Started
- Estimated Time: 1 hour
- Dependencies: Task 4
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - test/users.e2e-spec.ts

**TDD Notes:**
- Test full request/response cycle
- Test with real database (test DB)
- Test all error scenarios

## Task 6: Add Validation Middleware
- Status: [ ] Not Started
- Estimated Time: 0.5 hours
- Dependencies: Task 4
- Acceptance Criteria:
  - [ ] Tests written and failing (Red)
  - [ ] Implementation complete
  - [ ] Tests passing (Green)
- Files to Create/Modify:
  - src/api/users/validation/uuid.validator.ts
  - src/api/users/validation/uuid.validator.spec.ts

**TDD Notes:**
- Test UUID validation accepts valid UUIDs
- Test UUID validation rejects invalid formats
- Test integration with controller

## Task 7: Update API Documentation
- Status: [ ] Not Started
- Estimated Time: 0.5 hours
- Dependencies: Task 4
- Acceptance Criteria:
  - [ ] API docs updated
  - [ ] Swagger/OpenAPI spec updated
  - [ ] Examples added
- Files to Create/Modify:
  - docs/api/users.md
  - src/api/users/users.controller.ts (add Swagger decorators)

**Documentation Notes:**
- Document endpoint: GET /api/users/:id
- Document request/response formats
- Document error codes
- Add usage examples
