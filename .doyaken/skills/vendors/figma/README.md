# Figma Skills

Skills for design-to-code workflows using Figma MCP.

## Available Skills

| Skill | Description |
|-------|-------------|
| `figma:design-to-code` | Convert Figma frames to React/HTML code |
| `figma:extract-tokens` | Extract design tokens from Figma |
| `figma:a11y-audit` | Audit Figma designs for accessibility |

## MCP Setup

```bash
# Remote (browser Figma)
claude mcp add figma --url https://api.figma.com/mcp

# Desktop (requires Figma Desktop app)
# Enable MCP in Figma Desktop settings
```

## Usage

```bash
# Convert design to code
doyaken skill figma:design-to-code --frame="Hero Section"

# Extract design tokens
doyaken skill figma:extract-tokens --file=FILE_ID

# Accessibility audit
doyaken skill figma:a11y-audit --frame="Login Form"
```

## See Also

- [Figma Prompts](../../../prompts/vendors/figma/)
- [Figma MCP Config](../../../templates/mcp/figma.json)
