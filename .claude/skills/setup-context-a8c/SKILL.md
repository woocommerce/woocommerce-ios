---
name: setup-context-a8c
description: Set up the ContextA8C MCP server for accessing Automattic internal resources (Slack, Linear, P2s, GitHub Enterprise, etc.)
user-invocable: true
allowed-tools: "Bash, Read"
---

Set up the ContextA8C MCP server for the current user.

**IMPORTANT**: The `claude` CLI binary may exist on the system regardless of which client the user is actually running. Do NOT use `which claude` to detect the client. Always ask the user first.

## Step 1: Identify the client

Ask the user which AI client they are currently using. Present these options:
- **Claude Code** (CLI in terminal)
- **Claude Desktop** (macOS/Windows app)
- **Cursor**
- **VS Code**
- **Other**

Do NOT proceed until the user confirms their client. The setup steps differ per client and applying the wrong one will silently fail (e.g., `claude mcp add` registers for Claude Code only, not Claude Desktop).

## Step 2: Check prerequisites

```bash
npx --version
```

If npx is not found, tell the user to install Node.js (v18+) and stop.

## Step 3: Register MCP (client-specific)

### Claude Code (CLI)

Run the setup script:
```bash
bash .claude/skills/setup-context-a8c/setup-for-claude-code.sh
```

### Claude Desktop

Guide the user through these manual steps (the agent cannot do this for them):
1. Go to the ContextA8C setup page on MC (search "ContextA8C" in MC)
2. Select "Claude Desktop"
3. Download the MCPB bundle file
4. Double-click it — Claude Desktop will walk through the rest
5. If it fails with a Node version error: install Node from nodejs.org, quit and restart Claude Desktop, then double-click the MCPB file again

### Cursor / VS Code / Other MCP clients

Tell the user to add this JSON config to their client's MCP settings file:
- **Cursor**: `.cursor/mcp.json`
- **VS Code**: `.vscode/mcp.json`

```json
{
  "mcpServers": {
    "context-a8c": {
      "command": "npx",
      "args": ["-y", "@automattic/mcp-context-a8c"]
    }
  }
}
```

## Step 4: Connect accounts

Tell the user to connect their Automattic accounts in a browser:

1. Open the ContextA8C setup page on MC in a browser
2. Enable and authorize each provider they want (Slack, Linear, WordPress.com, GitHub, etc.)
3. Some providers require OAuth, others are simple toggles
4. This is a one-time setup per provider

Wait for the user to confirm they have connected their accounts.

## Step 5: Restart

Tell the user to fully quit and relaunch their AI tool (not just start a new session) for the MCP server to load.
