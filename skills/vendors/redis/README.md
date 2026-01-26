# Redis Skills

Skills for Redis implementation and optimization.

## Available Skills

| Skill | Description |
|-------|-------------|
| `redis:cache-setup` | Set up application caching with Redis |
| `redis:session-store` | Configure Redis session storage |
| `redis:rate-limiter` | Implement rate limiting with Redis |

## MCP Setup

```bash
# Add Redis MCP
claude mcp add redis --command 'npx -y @redis/mcp-redis'

# With connection URL
claude mcp add redis --command 'npx -y @redis/mcp-redis' --env REDIS_URL=redis://localhost:6379
```

## Usage

```bash
# Set up caching
doyaken skill redis:cache-setup --strategy=cache-aside

# Configure sessions
doyaken skill redis:session-store --framework=express

# Add rate limiting
doyaken skill redis:rate-limiter --type=sliding-window
```

## See Also

- [Redis Prompts](../../../prompts/vendors/redis/)
- [Redis MCP Config](../../../templates/mcp/redis.json)
