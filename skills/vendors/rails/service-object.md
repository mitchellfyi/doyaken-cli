---
name: rails:service-object
description: Generate a service object following Rails patterns
args:
  - name: name
    description: Service name (e.g., Users::Register)
    default: ""
  - name: with_result
    description: Include Result object pattern
    default: "true"
---

# Create Rails Service Object

You are creating a service object following Rails best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
Service: {{ARGS.name}}
With Result: {{ARGS.with_result}}

## Process

### 1. Create Service

{{include:vendors/rails/patterns.md}}

```ruby
# app/services/{{ARGS.name | underscore}}.rb
module {{ARGS.name | split('::') | first}}
  class {{ARGS.name | split('::') | last}}
    def initialize(params)
      @params = params
    end

    def call
      # Business logic here
    end

    private

    attr_reader :params
  end
end
```

### 2. Implement Logic

Structure the service:
- Initialize with dependencies
- Single public `call` method
- Private helper methods
- Clear error handling

{{#if with_result == "true"}}
### 3. Add Result Object

```ruby
class Result
  attr_reader :value, :errors

  def initialize(success:, value: nil, errors: nil)
    @success = success
    @value = value
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(errors)
    new(success: false, errors: errors)
  end
end
```
{{/if}}

### 4. Add Tests

Create specs for success and failure cases.

## Output

```markdown
## Service Object Created

**Service**: {{ARGS.name}}
**Path**: `app/services/{{ARGS.name | underscore}}.rb`

### Files Created
- `app/services/{{ARGS.name | underscore}}.rb`
{{#if with_result == "true"}}
- `app/services/result.rb` (if not exists)
{{/if}}
- `spec/services/{{ARGS.name | underscore}}_spec.rb`

### Usage
```ruby
result = {{ARGS.name}}.new(params).call
# or
result = {{ARGS.name}}.call(params)

if result.success?
  # handle success
else
  # handle failure
end
```

### Next Steps
- [ ] Implement business logic
- [ ] Add error handling
- [ ] Write tests
- [ ] Use in controller
```
