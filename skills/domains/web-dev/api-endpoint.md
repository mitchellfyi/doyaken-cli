---
name: api-endpoint
description: Generate a REST API endpoint with validation, tests, and docs
args:
  - name: path
    description: API path (e.g., /api/users)
    required: true
  - name: method
    description: HTTP method
    default: GET
---

# API Endpoint Generation

Create a new API endpoint at **{{ARGS.method}} {{ARGS.path}}**.

## Requirements

1. Create the route handler with proper request/response typing
2. Add input validation (query params, body, path params)
3. Implement error handling with appropriate HTTP status codes
4. Add integration tests
5. Document the endpoint (OpenAPI/Swagger or inline docs)

## Implementation Checklist

- [ ] Route handler created
- [ ] Input validation with error messages
- [ ] Authentication/authorization checks (if applicable)
- [ ] Database queries use parameterized statements
- [ ] Response follows API conventions (envelope, pagination)
- [ ] Tests cover success, validation errors, and auth failures
- [ ] Rate limiting considerations
