# ContextA8C (Automattic Internal Resources)

ContextA8C is an Automattic MCP server (`@automattic/mcp-context-a8c`) that gives AI tools access to internal resources. It works with any MCP-compatible client (Claude Code, Cursor, VS Code, etc.). It is configured per-user and requires a one-time browser-based account connection.

## Setup

**Prerequisites**: Node.js v18+ (npx must be available).

### 1. Connect accounts (all clients)

Visit the ContextA8C setup page on MC (Automatticians: search "ContextA8C" on MC) and authorize each provider you want to use (Slack, Linear, GitHub, etc.). Some require OAuth, others are simple toggles. This is a one-time step per provider.

### 2. Configure your MCP client

| Client | Setup |
|--------|-------|
| Claude Code (requires `claude` CLI binary) | `claude mcp add --transport stdio --scope user context-a8c -- npx -y @automattic/mcp-context-a8c` (or run `/setup-context-a8c` skill). For environments without the `claude` binary, add the JSON config below manually — see `agent-environment-awareness.md`. |
| Claude Desktop | Add manually through Desktop settings: command `npx`, args `-y @automattic/mcp-context-a8c`. Do not edit config files — see `agent-environment-awareness.md`. |
| Cursor | Add JSON config below to `.cursor/mcp.json` |
| VS Code | Add JSON config below to `.vscode/mcp.json` |
| Other MCP clients | Use JSON config below in the client's MCP settings |

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

## Providers

| Provider | Use For |
|----------|---------|
| `mgs` | Broad search across P2s, Field Guide, internal docs (preferred for search) |
| `slack` | Messages, channels, threads, DMs |
| `wpcom` | Specific P2 posts, WordPress.com content, A8C Reader |
| `fieldguide` | Field Guide articles (policies, processes, how-to guides) |
| `github` | Public GitHub repos (github.com) |
| `github-a8c` | Internal GitHub Enterprise |
| `linear` | Linear issues, projects, team assignments |

Additional providers (matticspace, zendesk, etc.) may be available depending on connected accounts. Use the load-provider tool to discover what's available.

## Usage Pattern

ContextA8C uses a two-step progressive disclosure pattern:

1. **Load a provider** — returns the list of available tools and their parameter schemas
2. **Execute a tool** — call a specific tool within the loaded provider

Load a provider once per session. The response describes available tools and parameters, so there is no need to hardcode tool names.

### Claude Code tool names

In Claude Code, tools are prefixed with `mcp__context-a8c__`:
```
mcp__context-a8c__context-a8c-load-provider(provider: "slack")
mcp__context-a8c__context-a8c-execute-tool(provider: "slack", tool: "search", params: {"query": "..."})
```

If these tools are not available in a Claude Code session, ContextA8C is not configured. Suggest running `/setup-context-a8c` once, then continue without it.

## When to Use

Proactively use ContextA8C when it adds context beyond what the local codebase provides:

- **Task research**: When given a `WOOMOB-XXXX` issue ID, fetch the task description via `linear` or search via `mgs`
- **URL resolution**: When given internal Slack, P2, or Linear URLs, fetch the content via the appropriate provider
- **Internal docs**: Search Field Guide or P2s for policies, prior discussions, or design decisions via `mgs` or `fieldguide`
- **Cross-platform parity**: Search `woocommerce/woocommerce-android` PRs via `github`

## When ContextA8C Errors or is Unavailable

When a ContextA8C call fails, do NOT silently give up. Follow this sequence:

1. **Diagnose**: Tell the user what error occurred (permission denied, invalid provider, auth error, tool not found, etc.)
2. **Suggest a fix**: Give the user concrete human-actionable steps based on the error type. Never tell the user to run agent skills or commands that only the agent can execute — those are for the agent, not the user.
   - **Permission denied / Access forbidden**: The MCP may be disabled or misconfigured. Ask the user to check that ContextA8C is enabled (not disabled) in their MCP client settings and that accounts are connected on the ContextA8C setup page on MC
   - **Invalid provider name**: Try `mgs` as a fallback for search tasks. List known valid providers for the user
   - **Auth errors**: Ask the user to re-visit the ContextA8C setup page on MC and re-authorize the affected provider
   - **Tool not found / MCP not recognized**: The MCP is not configured. Offer to run the setup (the agent should execute `/setup-context-a8c` itself, not ask the user to type it). For non-Claude Code clients, point the user to the JSON config in the Setup section above
   - **Other errors**: Show the error details and suggest restarting the AI tool session
3. **Ask the user**: Offer to help troubleshoot further or to proceed without ContextA8C
4. **Fall back gracefully**: If the user chooses to skip, continue with codebase, git history, or ask the user to paste the needed information directly

Do NOT:
- Silently skip ContextA8C without telling the user what went wrong
- Tell the user to run agent skills or slash commands — those are for the agent to execute, not the user
- Assume which environment the user is running — ask them (see `agent-environment-awareness.md`). The `claude` CLI binary may exist on the system even when the user is running Claude Desktop. MCP setup steps differ per environment
- Retry the same failing call more than once in a session
- Block on ContextA8C — always offer to proceed without it
