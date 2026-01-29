---
name: rails:api-endpoint
description: Create a Rails API endpoint with best practices
args:
  - name: resource
    description: Resource name (e.g., posts, users)
    default: ""
  - name: actions
    description: Actions to implement (index,show,create,update,destroy)
    default: "index,show,create,update,destroy"
  - name: version
    description: API version (v1, v2)
    default: "v1"
---

# Create Rails API Endpoint

You are creating a RESTful API endpoint following Rails best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
Resource: {{ARGS.resource}}
Actions: {{ARGS.actions}}
Version: {{ARGS.version}}

## Process

### 1. Generate Files

Create the following structure:

```
app/
├── controllers/
│   └── api/
│       └── {{ARGS.version}}/
│           └── {{ARGS.resource}}_controller.rb
├── serializers/
│   └── {{ARGS.resource}}_serializer.rb
└── policies/
    └── {{ARGS.resource}}_policy.rb (optional)
```

### 2. Implement Controller

{{include:vendors/rails/api.md}}

```ruby
# app/controllers/api/{{ARGS.version}}/{{ARGS.resource}}_controller.rb
module Api
  module {{ARGS.version | upcase}}
    class {{ARGS.resource | camelize}}Controller < BaseController
      # Implement requested actions
    end
  end
end
```

### 3. Add Serialization

{{include:vendors/rails/patterns.md}}

Create serializer for consistent JSON output.

### 4. Add Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :{{ARGS.version}} do
    resources :{{ARGS.resource}}, only: [{{ARGS.actions}}]
  end
end
```

### 5. Add Tests

Create request specs for each action.

## Output

```markdown
## API Endpoint Created

**Resource**: {{ARGS.resource}}
**Version**: {{ARGS.version}}
**Actions**: {{ARGS.actions}}

### Files Created
- `app/controllers/api/{{ARGS.version}}/{{ARGS.resource}}_controller.rb`
- `app/serializers/{{ARGS.resource}}_serializer.rb`
- `spec/requests/api/{{ARGS.version}}/{{ARGS.resource}}_spec.rb`

### Endpoints
| Method | Path | Action |
|--------|------|--------|
| GET | /api/{{ARGS.version}}/{{ARGS.resource}} | index |
| GET | /api/{{ARGS.version}}/{{ARGS.resource}}/:id | show |
| POST | /api/{{ARGS.version}}/{{ARGS.resource}} | create |

### Next Steps
- [ ] Add authentication
- [ ] Configure authorization
- [ ] Add rate limiting
- [ ] Write tests
```
