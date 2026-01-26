# Redis Prompts

Redis patterns, data structures, and caching strategies.

## Prompts

| Prompt | Description |
|--------|-------------|
| [data-structures.md](data-structures.md) | Redis data types and usage patterns |
| [caching.md](caching.md) | Caching strategies and patterns |
| [patterns.md](patterns.md) | Common Redis patterns (pub/sub, queues, etc.) |

## MCP Integration

Redis provides an official MCP server:

```bash
# Add Redis MCP
claude mcp add redis

# With connection string
claude mcp add redis --env REDIS_URL=redis://localhost:6379
```

## When to Apply

Use these prompts when:
- Implementing caching layers
- Building real-time features
- Managing session data
- Creating job queues
- Rate limiting

## Key Concepts

### Data Structures

| Type | Use Case |
|------|----------|
| String | Caching, counters, flags |
| Hash | Objects, user sessions |
| List | Queues, activity feeds |
| Set | Tags, unique items |
| Sorted Set | Leaderboards, rankings |
| Stream | Event logs, messaging |

### Connection Patterns

- **Single instance**: Development, simple apps
- **Sentinel**: High availability
- **Cluster**: Horizontal scaling

## References

- [Redis Documentation](https://redis.io/docs/)
- [Redis MCP Server](https://redis.io/blog/introducing-model-context-protocol-mcp-for-redis/)
- [Redis Best Practices](https://redis.io/docs/best-practices/)
