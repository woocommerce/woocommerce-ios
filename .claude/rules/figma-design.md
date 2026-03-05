# Figma Design Integration

## Proactive Design Awareness

When working on any UI-related task:
1. **Check for Figma links first** — if a Linear issue is available, inspect its description for Figma URLs before starting UI work
2. **Ask the user for designs** — if no Figma link is found but the task involves visible UI changes, ask the user whether design references are available. Designs help ensure pixel-accurate implementation
3. **Always fetch design context before writing UI code** when a Figma link is available

## Setup

The Figma MCP is a remote HTTP server at `https://mcp.figma.com/mcp`. It requires a **one-time OAuth flow** — the first connection opens a browser window for Figma login.

**Prerequisites**: A Figma account with access to the relevant design files.

### Configure Your MCP Client

| Client | Setup |
|--------|-------|
| Claude Code (CLI) | Already configured via `.mcp.json` — no action needed |
| Claude Desktop | Add manually through Desktop settings (see Desktop note below) |
| Cursor | Add to `.cursor/mcp.json` |
| VS Code | Add to `.vscode/mcp.json` |
| Other MCP clients | Use the JSON config below in the client's MCP settings |

JSON config for Cursor, VS Code, and other clients that support a JSON MCP config file:
```json
{
  "mcpServers": {
    "figma": {
      "url": "https://mcp.figma.com/mcp",
      "type": "http"
    }
  }
}
```

**Claude Desktop** (two options):
1. **Browse built-in connectors** (preferred): Open Claude Desktop's settings or integrations area, browse available connectors/integrations, find the Figma connector, and enable it. The exact menu labels may vary across Desktop versions — look for sections like "Integrations", "Connectors", "MCP Servers", or similar. Follow the on-screen prompts to authorize with Figma.
2. **Manual MCP config**: If the built-in connector is not available, add the Figma MCP manually through Desktop settings using the `mcp-remote` bridge: command `npx`, args `mcp-remote https://mcp.figma.com/mcp`. Do not edit config files directly — see `agent-environment-awareness.md`.

After adding the config or enabling the connector, **restart the client** if needed to trigger the OAuth flow in the browser.

## When Figma MCP is Unavailable

When a Figma link is available but `mcp__figma__*` tools are not present in the session, the agent must NOT silently skip — follow this sequence:

1. **Tell the user**: "Figma MCP is not connected — I can't fetch design context from this link."
2. **Ask which environment** the user is running (see `agent-environment-awareness.md`). Do NOT assume Claude Code CLI — the presence of `.mcp.json` in the repo is not evidence of your runtime environment. Then provide the environment-specific setup steps from the **Setup** section above.
   - For **Claude Desktop**: follow the two-option procedure in the **Setup** section above (built-in connector preferred, manual MCP config as fallback). Do NOT try to edit config files — this is unreliable for Desktop. Never suggest `claude mcp add` — that's CLI-only.
   - For **Claude Code**: check if `.mcp.json` already has the Figma entry. If it does, the issue is likely OAuth — suggest restarting the session.
3. **Fall back gracefully**: If the user can't set up Figma MCP right now, offer alternatives:
   - Ask the user to paste a screenshot or describe the design
   - Use the Figma link in a browser manually and relay details via chat
   - Proceed with best-effort implementation based on existing code patterns
4. **Do NOT** retry a failing Figma MCP call more than once in a session

## Figma MCP

Authentication is via OAuth (one-time browser flow on first use — see Setup above).

### Key Tools
- **`get_design_context`** — Layout structure, styles, and code suggestions for a Figma frame/node. Pass the full Figma URL
- **`get_screenshot`** — Visual screenshot of a Figma frame for comparison
- **`get_variable_defs`** — Design tokens (colors, spacing, typography) used in a selection
- **`get_metadata`** — Sparse XML with layer IDs, names, types, positions, and sizes
- **`get_code_connect_map`** — Mappings between Figma nodes and codebase components

### When to Use
- When a Figma URL is available (from a Linear issue, user message, or PR description)
- When implementing UI and design references would improve accuracy
- When visually verifying implementation against designs (use `get_screenshot` alongside `/snapshot` if available)

### When NOT to Use
- For non-UI changes (business logic, networking, storage)
- Do not proactively search for Figma files — only use links that are provided or found in Linear issues

## Extracting Figma Links from Linear Issues

When working on a Linear issue (via ContextA8C Linear provider), check the issue description for Figma URLs. Common patterns:
- `https://www.figma.com/design/<FILE_KEY>/<NAME>?node-id=<NODE_ID>`
- `https://www.figma.com/file/<FILE_KEY>/<NAME>?node-id=<NODE_ID>`

If a Figma link is found:
1. Call `get_design_context` with the full URL to get layout and style details
2. Call `get_screenshot` to get a visual reference image
3. Optionally call `get_variable_defs` for design token values

URLs without a `node-id` parameter return data for the entire page (noisy). Prefer links with specific node IDs.

## Mapping Figma to iOS

`get_design_context` returns React + Tailwind code by default. Translate to iOS:

### SwiftUI Mapping
| Figma | SwiftUI |
|-------|---------|
| Auto Layout (horizontal) | `HStack(spacing:)` |
| Auto Layout (vertical) | `VStack(spacing:)` |
| Padding | `.padding()` modifiers |
| Fill container | `.frame(maxWidth: .infinity)` |
| Fixed size | `.frame(width:height:)` |
| Border radius | `.clipShape(RoundedRectangle(cornerRadius:))` |
| Text styles | `.font()` modifier |
| Opacity | `.opacity()` |
| Shadow | `.shadow()` |

### POS Views
Map Figma values to POS design tokens — do NOT use hardcoded values:
- **Spacing** → `POSSpacing` (`.xSmall` through `.xxLarge`)
- **Padding** → `POSPadding` (`.xSmall` through `.xxLarge`)
- **Typography** → `POSFontStyle` (`.posHeadingBold`, `.posBodyLargeRegular()`, etc.)
- **Colors** → `Color+POSColorPalette` (`.posPrimary`, `.posSurface`, `.posError`, etc.)

### Main App Views
- Use existing color assets from the project's asset catalog
- Use system fonts with appropriate text styles
- Follow spacing patterns in nearby existing code
