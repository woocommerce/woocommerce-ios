#!/usr/bin/env bash

# Sets up the ContextA8C MCP server for Claude Code (CLI).
# Called by the setup-context-a8c skill when the user selects Claude Code.

set -euo pipefail

# Find claude binary
CLAUDE_BIN=""
if command -v claude &>/dev/null; then
    CLAUDE_BIN="claude"
elif [[ -x "$HOME/.local/bin/claude" ]]; then
    CLAUDE_BIN="$HOME/.local/bin/claude"
else
    echo "ERROR: Could not find the 'claude' binary. Is Claude Code installed?"
    exit 1
fi

# Check if context-a8c is already registered
if "$CLAUDE_BIN" mcp list 2>&1 | grep -q "context-a8c"; then
    echo "context-a8c is already registered in Claude Code."
    exit 0
fi

# Register the MCP server
echo "Registering context-a8c MCP server..."
"$CLAUDE_BIN" mcp add --transport stdio --scope user context-a8c -- npx -y @automattic/mcp-context-a8c

echo "Done. context-a8c has been registered for Claude Code."
