# Rails Skills

Skills for Ruby on Rails development.

## Available Skills

| Skill | Description |
|-------|-------------|
| `rails:api-endpoint` | Create a new API endpoint with best practices |
| `rails:service-object` | Generate a service object |
| `rails:query-optimize` | Analyze and optimize database queries |

## Usage

```bash
# Create API endpoint
doyaken skill rails:api-endpoint --resource=posts --actions=index,show,create

# Create service object
doyaken skill rails:service-object --name=Users::Register

# Optimize queries
doyaken skill rails:query-optimize --model=User
```

## See Also

- [Rails Prompts](../../../prompts/vendors/rails/)
- [PostgreSQL Prompts](../../../prompts/vendors/postgres/)
