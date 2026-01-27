---
description: Apply api-rest methodology
---

# API Design Principles

## REST Fundamentals

### Resource-Oriented URLs
```
Good:
GET    /users              # List users
GET    /users/123          # Get user 123
POST   /users              # Create user
PUT    /users/123          # Update user 123
DELETE /users/123          # Delete user 123

Bad:
GET    /getUsers
POST   /createUser
POST   /users/delete/123
```

### HTTP Methods
| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| GET | Read resource | Yes | Yes |
| POST | Create resource | No | No |
| PUT | Replace resource | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove resource | Yes | No |

### Status Codes
| Code | Meaning | Use When |
|------|---------|----------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Valid auth, no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate, version mismatch |
| 422 | Unprocessable | Valid syntax, invalid semantics |
| 500 | Server Error | Unexpected failure |

## Request Design

### Query Parameters
```
# Filtering
GET /users?status=active&role=admin

# Pagination
GET /users?page=2&limit=20
GET /users?cursor=abc123&limit=20  # Cursor-based (preferred)

# Sorting
GET /users?sort=createdAt:desc

# Field selection
GET /users?fields=id,name,email
```

### Request Body
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "preferences": {
    "notifications": true
  }
}
```

**Guidelines:**
- Use camelCase for JSON keys
- Accept and return JSON
- Use ISO 8601 for dates: `2024-01-15T10:30:00Z`
- Use consistent null handling

## Response Design

### Single Resource
```json
{
  "id": "usr_123",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### Collection
```json
{
  "data": [
    { "id": "usr_123", "name": "John" },
    { "id": "usr_456", "name": "Jane" }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "hasMore": true,
    "nextCursor": "xyz789"
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ],
    "requestId": "req_abc123"
  }
}
```

## Versioning

### URL Path (Recommended)
```
GET /v1/users
GET /v2/users
```

### Header
```
GET /users
Accept: application/vnd.api+json; version=2
```

### Query Parameter
```
GET /users?version=2
```

**Guidelines:**
- Major versions only (v1, v2)
- Support previous version for 6-12 months
- Document deprecation timeline
- Provide migration guides

## Pagination

### Cursor-Based (Recommended)
```json
{
  "data": [...],
  "pagination": {
    "nextCursor": "eyJpZCI6MTIzfQ==",
    "hasMore": true
  }
}

// Next request
GET /users?cursor=eyJpZCI6MTIzfQ==&limit=20
```

**Pros:** Consistent with real-time data, scales well
**Cons:** Can't jump to specific page

### Offset-Based
```json
{
  "data": [...],
  "pagination": {
    "total": 1000,
    "page": 5,
    "limit": 20,
    "totalPages": 50
  }
}

// Next request
GET /users?page=6&limit=20
```

**Pros:** Can jump to any page
**Cons:** Inconsistent if data changes, slow for large offsets

## Authentication

### Bearer Token
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### API Key
```
X-API-Key: sk_live_abc123...
```

**Guidelines:**
- Use HTTPS always
- Short-lived access tokens (15min - 1hr)
- Refresh tokens for long sessions
- Include token expiry in response
- Rate limit by API key/user

## Rate Limiting

### Response Headers
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640000000
```

### 429 Response
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retryAfter": 60
  }
}
```

## Nested Resources

### When to Nest
```
# Good - strong parent-child relationship
GET /users/123/orders
GET /orders/456/items

# Bad - resources are independent
GET /users/123/products  # Products aren't owned by users
```

### Limit Nesting Depth
```
# Good
GET /users/123/orders

# Avoid
GET /users/123/orders/456/items/789/variants
```

## Bulk Operations

### Batch Create
```
POST /users/batch
{
  "users": [
    { "email": "a@example.com" },
    { "email": "b@example.com" }
  ]
}
```

### Batch Response
```json
{
  "results": [
    { "status": "created", "id": "usr_123" },
    { "status": "error", "error": { "message": "Email exists" } }
  ],
  "summary": {
    "total": 2,
    "succeeded": 1,
    "failed": 1
  }
}
```

## API Design Checklist

- [ ] Resources are nouns, not verbs
- [ ] Consistent naming conventions
- [ ] Appropriate HTTP methods
- [ ] Correct status codes
- [ ] Consistent error format
- [ ] Pagination for lists
- [ ] Versioning strategy
- [ ] Rate limiting
- [ ] Authentication documented
- [ ] Examples for all endpoints

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
