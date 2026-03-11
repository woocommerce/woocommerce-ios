# Agent Environment Awareness

**Never assume which environment you are in.** When MCP tools are missing or MCP setup is needed, ask the user which environment they're running (Claude Code CLI, Claude Desktop, Cursor, VS Code, etc.) before giving any setup guidance. The presence of `.mcp.json` in the project does NOT mean you are in Claude Code CLI — the file is checked into the repo and visible to all environments. Claude Code CLI and Claude Desktop have nearly identical capabilities, so you cannot distinguish them from tool availability alone.

These instructions are shared across multiple environments. Most instructions (build commands, git, testing, code conventions, skills, rules) work identically everywhere. The differences are narrow but matter when they come up.

## MCP Configuration

`.mcp.json` in the project root is the **single source of truth** for MCP servers (Figma, mobile-mcp, etc.).

- **Claude Code (CLI)** auto-loads `.mcp.json`. If authentication is required, ask the user to type `/mcp`, select their MCP of choice and proceed with authentication manually.
- **Other environments** (Claude Desktop, Cursor, VS Code, etc.) may not read `.mcp.json`. If expected MCP tools are missing, the agent should:
  1. Read `.mcp.json` to identify the needed servers
  2. Ask the user which environment they're in (don't guess)
  3. Guide the user to add the MCP server through their environment's settings

Known MCP config locations:
| Environment | Config location |
|-------------|----------------|
| Claude Code (CLI) | `.mcp.json` (auto-loaded) |
| Claude Desktop | Add manually through Desktop settings (not via config file editing — see below) |

For other environments, ask the user where their MCP config lives.

**Claude Desktop**: Do NOT try to programmatically edit config files — this is unreliable and may not be picked up by the app. Instead, provide the user with the server details (name, command, args) and guide them to add the MCP server manually through Claude Desktop's Settings UI. For HTTP MCP servers (like Figma), the user needs the `mcp-remote` bridge: command `npx`, args `mcp-remote <url>`.

## `claude` CLI Commands

Commands like `claude mcp add` require the `claude` CLI binary, which is **only available in Claude Code CLI**. In other environments (including Claude Desktop), guide the user to add the MCP server through their environment's settings.

## When Environment Matters

- **MCP server setup** — config location differs
- **`claude` CLI commands** — only work in Claude Code CLI

For everything else — build commands, git, testing, code conventions, skills, rules, settings — the environment doesn't matter.

## How to Determine Your Environment

**Ask the user.** Don't infer from tool availability or from the presence of `.mcp.json` — these are not reliable signals.
