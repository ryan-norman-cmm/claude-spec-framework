# Design: Get User by ID API

## Architecture

### Endpoint
```
GET /api/users/:id
```

### Flow
```
Client Request
  ↓
Route Handler (users.controller.ts)
  ↓
Service Layer (users.service.ts)
  ↓
Repository Layer (users.repository.ts)
  ↓
Database (PostgreSQL)
  ↓
Response
```

## Data Models

### User Entity
```typescript
interface User {
  id: string;           // UUID
  name: string;
  email: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### UserDTO (Response)
```typescript
interface UserDTO {
  id: string;
  name: string;
  email: string;
  createdAt: string;    // ISO 8601
}
```

### Error Response
```typescript
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
  }
}
```

## API Contract

### Success Response (200)
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "John Doe",
  "email": "john@example.com",
  "createdAt": "2025-01-15T10:30:00Z"
}
```

### Not Found (404)
```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User not found"
  }
}
```

### Bad Request (400)
```json
{
  "error": {
    "code": "INVALID_USER_ID",
    "message": "Invalid user ID format",
    "details": {
      "field": "id",
      "expected": "UUID v4"
    }
  }
}
```

## Implementation Details

### Controller
```typescript
// src/api/users/users.controller.ts
@Get(':id')
async getUser(@Param('id') id: string): Promise<UserDTO> {
  // Validate UUID format
  if (!isUUID(id)) {
    throw new BadRequestException('Invalid user ID format');
  }

  const user = await this.usersService.findById(id);

  if (!user) {
    throw new NotFoundException('User not found');
  }

  return this.toDTO(user);
}
```

### Service
```typescript
// src/api/users/users.service.ts
async findById(id: string): Promise<User | null> {
  return this.usersRepository.findOne({ where: { id } });
}
```

### Validation
- UUID validation using `uuid` package
- Input sanitization
- Error handling middleware

## Testing Strategy

### Unit Tests
- Controller: HTTP status codes, DTOs
- Service: Business logic
- Repository: Database queries

### Integration Tests
- End-to-end API request/response
- Database integration
- Error scenarios

## Files to Create/Modify

- `src/api/users/users.controller.ts`
- `src/api/users/users.service.ts`
- `src/api/users/users.repository.ts`
- `src/api/users/dto/user.dto.ts`
- `src/api/users/users.controller.spec.ts`
- `src/api/users/users.service.spec.ts`
