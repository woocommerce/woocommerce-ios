#!/bin/bash
#
# Stop hook for smoke test — random halt detection
#
# Fires when the agent tries to stop on its own. Blocks if the smoke
# test hasn't generated its HTML report yet (indicating incomplete run).
#
# Does NOT fire on user-initiated stops (Escape, Ctrl+C, /stop).
#
# Scoped to the smoke-test skill via frontmatter — only runs during
# smoke test execution.

set -euo pipefail

INPUT=$(cat)

# If this is a retry (stop_hook_active=true), allow the stop to prevent
# infinite loops. The agent already got one chance to continue.
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# Get the current session ID from the hook input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0  # No session ID, can't check — allow stop
fi

# Find the run folder for THIS session by checking run.json markers.
# The skill writes run.json with the session_id at the start of each run.
RUN_DIR=""
for dir in .claude/smoke-test-runs/* /tmp/woo-smoke-test-*; do
  [ -d "$dir" ] || continue
  if [ -f "$dir/run.json" ]; then
    DIR_SESSION=$(jq -r '.session_id // empty' "$dir/run.json" 2>/dev/null)
    if [ "$DIR_SESSION" = "$SESSION_ID" ]; then
      RUN_DIR="$dir"
      break
    fi
  fi
done

# No run folder for this session — might be a different kind of stop
# (e.g., credential setup, not an actual test run). Allow stop.
if [ -z "$RUN_DIR" ]; then
  exit 0
fi

# Check if report.html exists in THIS session's run folder
if [ -f "$RUN_DIR/report.html" ]; then
  exit 0  # Report exists — run is complete
fi

# No report found for this session — block the stop
cat <<'BLOCK'
{
  "decision": "block",
  "reason": "The smoke test is still in progress — no HTML report has been generated yet. Do not stop. Continue running the remaining test sections, then generate the HTML report and open it in the browser. If you are stuck, ask the user for help rather than stopping."
}
BLOCK
exit 0
