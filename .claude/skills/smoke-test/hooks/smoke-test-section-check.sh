#!/bin/bash
#
# PostToolUse hook for smoke test — section skip detection
#
# Fires after TaskUpdate calls. Checks that earlier tasks aren't being
# skipped without justification when a later task is completed.
#
# Scoped to the smoke-test skill via frontmatter — only runs during
# smoke test execution.

set -euo pipefail

INPUT=$(cat)

# Extract the tool input (TaskUpdate arguments)
TASK_STATUS=$(echo "$INPUT" | jq -r '.tool_input.status // empty')

# Only check when a task is being marked completed
if [ "$TASK_STATUS" != "completed" ]; then
  exit 0
fi

TASK_ID=$(echo "$INPUT" | jq -r '.tool_input.taskId // empty')

# If no task ID, nothing to check
if [ -z "$TASK_ID" ]; then
  exit 0
fi

# Check the tool response for the task list state
# The TaskUpdate response includes info about the task, but we need to check
# if prior tasks were skipped. We can infer this from the last_assistant_message
# or from the tool response. Since we don't have the full task list in the hook
# input, we check the assistant's recent messages for skip indicators.

LAST_MSG=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Check if any earlier tasks are still pending by looking at the response
# The tool_response for TaskUpdate just confirms the update. We need to rely
# on the assistant message context for skip detection.

# For now, we output a reminder to the agent about valid skip reasons.
# The real enforcement comes from the message content — if a task was
# marked completed but the agent skipped running it, the lack of
# screenshots/observations will be visible in the report.

# Check if the assistant message mentions skipping
ASSISTANT_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")

if echo "$ASSISTANT_MSG" | grep -qiE "skip|skipping|moving on|not testing|abandon"; then
  cat <<'BLOCK'
{
  "decision": "block",
  "reason": "It looks like you may be skipping a smoke test section. Before moving on, confirm this is for a valid reason:\n\n**Valid reasons to skip:**\n- (device-only) section running on simulator\n- (conditional) prerequisite not met\n- User explicitly chose to skip via AskUserQuestion\n- --section or --phase flag excluded it\n\n**NOT valid reasons (retry instead):**\n- WDA/connection flakiness — retry per the Connection Drops rules\n- 'Took too long' or 'was difficult'\n- Prior section failure (unless app crashed)\n- Framework timeouts\n\nIf you have a valid reason, state it clearly and continue. Otherwise, go back and complete the section."
}
BLOCK
  exit 0
fi

exit 0
