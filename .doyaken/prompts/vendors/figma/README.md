# Figma Prompts

Design-to-code workflows and Figma best practices for AI-assisted development.

## Prompts

| Prompt | Description |
|--------|-------------|
| [design-to-code.md](design-to-code.md) | Convert Figma designs to code |
| [design-systems.md](design-systems.md) | Design system extraction and tokens |
| [accessibility.md](accessibility.md) | Accessibility review from designs |

## MCP Integration

Figma provides an official MCP server for design context:

```bash
# Remote (browser-based Figma)
claude mcp add figma --url https://api.figma.com/mcp

# Desktop (local Figma app)
# Requires Figma Desktop app running
```

## When to Apply

Use these prompts when:
- Converting Figma designs to React/HTML/CSS code
- Extracting design tokens and variables
- Building or updating component libraries
- Reviewing designs for accessibility

## References

- [Figma MCP Server Docs](https://developers.figma.com/docs/figma-mcp-server/)
- [Figma MCP Blog Post](https://www.figma.com/blog/introducing-figma-mcp-server/)
- [What is MCP](https://www.figma.com/resource-library/what-is-mcp/)
