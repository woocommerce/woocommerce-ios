#!/bin/bash
#
# PostToolUse hook for smoke test — evidence-based section completion check
#
# Fires after TaskUpdate calls. Instead of text-matching for skip language,
# reads the progress.json state file to structurally verify:
#   1. The section being completed was marked in_progress first
#   2. At least one screenshot exists for the section
#   3. No earlier sections were silently skipped (still pending)
#
# Scoped to the smoke-test skill via frontmatter — only runs during
# smoke test execution.

set -euo pipefail

INPUT=$(cat)

# Only check when a task is being marked completed
TASK_STATUS=$(echo "$INPUT" | jq -r '.tool_input.status // empty')
if [ "$TASK_STATUS" != "completed" ]; then
  exit 0
fi

# Get session ID to find the run folder
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Find the run folder for THIS session
RUN_DIR=""
for dir in .smoke-test-runs/*; do
  [ -d "$dir" ] || continue
  if [ -f "$dir/run.json" ]; then
    DIR_SESSION=$(jq -r '.session_id // empty' "$dir/run.json" 2>/dev/null)
    if [ "$DIR_SESSION" = "$SESSION_ID" ]; then
      RUN_DIR="$dir"
      break
    fi
  fi
done

# No run folder yet — might be early setup (credential checks, build).
# Allow the task update.
if [ -z "$RUN_DIR" ]; then
  exit 0
fi

# Find progress files in the run folder.
# Single-agent mode: progress.json
# Parallel mode: progress-<worker>.json (one per worker)
# The hook runs in the context of the agent that called TaskUpdate.
# In parallel mode, each worker writes its own file. We check all of them
# since we don't know which worker triggered this hook.
PROGRESS_FILES=()
for f in "$RUN_DIR"/progress*.json; do
  [ -f "$f" ] && PROGRESS_FILES+=("$f")
done

if [ ${#PROGRESS_FILES[@]} -eq 0 ]; then
  exit 0  # No progress files yet — run hasn't started test sections.
fi

# Count how many progress files have an in_progress section.
# In parallel mode, multiple workers may have in_progress simultaneously.
IN_PROGRESS_FILES=()
for f in "${PROGRESS_FILES[@]}"; do
  HAS_IN_PROGRESS=$(jq -r '[.sections | to_entries[] | select(.value.status == "in_progress")] | length' "$f" 2>/dev/null || echo "0")
  if [ "$HAS_IN_PROGRESS" -gt 0 ]; then
    IN_PROGRESS_FILES+=("$f")
  fi
done

# If multiple files have in_progress sections, we're in parallel mode.
# The hook can't determine which worker triggered this TaskUpdate, so skip
# per-worker checks — the coordinator validates each worker's progress file
# after it returns. This avoids false blocks where Worker B is fine but
# Worker C (also running) hasn't taken screenshots yet.
if [ ${#IN_PROGRESS_FILES[@]} -gt 1 ]; then
  exit 0
fi

# Single in_progress file — use it for checks.
PROGRESS=""
if [ ${#IN_PROGRESS_FILES[@]} -eq 1 ]; then
  PROGRESS="${IN_PROGRESS_FILES[0]}"
fi

# Fallback: no in_progress files, use the first file with sections
if [ -z "$PROGRESS" ]; then
  for f in "${PROGRESS_FILES[@]}"; do
    HAS_SECTIONS=$(jq -r '.sections | length' "$f" 2>/dev/null || echo "0")
    if [ "$HAS_SECTIONS" -gt 0 ]; then
      PROGRESS="$f"
      break
    fi
  done
fi

if [ -z "$PROGRESS" ]; then
  exit 0  # No progress files with sections yet.
fi

# --- Structural checks against progress.json ---

# Find the section currently marked "in_progress"
CURRENT_SECTION=$(jq -r '
  .sections | to_entries[]
  | select(.value.status == "in_progress")
  | .key
' "$PROGRESS" 2>/dev/null || echo "")

# Find sections still "pending"
PENDING_SECTIONS=$(jq -r '
  [.sections | to_entries[] | select(.value.status == "pending") | .key]
  | join(", ")
' "$PROGRESS" 2>/dev/null || echo "")

# Find sections marked "completed"
COMPLETED_COUNT=$(jq -r '
  [.sections | to_entries[] | select(.value.status == "completed")] | length
' "$PROGRESS" 2>/dev/null || echo "0")

# Check 1: Is a section currently in_progress?
# If no section is in_progress but a task is being completed, the agent
# may be marking a section done without having started it in progress.json.
if [ -z "$CURRENT_SECTION" ]; then
  # Allow if this is a non-section task (setup, build, report generation)
  # by checking if there are any sections at all yet
  TOTAL_SECTIONS=$(jq -r '.sections | length' "$PROGRESS" 2>/dev/null || echo "0")
  if [ "$TOTAL_SECTIONS" -gt 0 ] && [ "$COMPLETED_COUNT" -gt 0 ]; then
    # Sections exist and some are completed, but none in_progress.
    # This is fine — the agent finished one and is completing its task.
    # But check if there are pending sections being skipped.
    if [ -n "$PENDING_SECTIONS" ]; then
      # Check ordering: are pending sections BEFORE completed ones?
      FIRST_PENDING_ORDER=$(jq -r '
        .expected_order as $order |
        [.sections | to_entries[] | select(.value.status == "pending") | .key] |
        map(. as $s | $order | to_entries[] | select(.value == $s) | .key) |
        min
      ' "$PROGRESS" 2>/dev/null || echo "999")

      LAST_COMPLETED_ORDER=$(jq -r '
        .expected_order as $order |
        [.sections | to_entries[] | select(.value.status == "completed") | .key] |
        map(. as $s | $order | to_entries[] | select(.value == $s) | .key) |
        max
      ' "$PROGRESS" 2>/dev/null || echo "0")

      if [ "$FIRST_PENDING_ORDER" -lt "$LAST_COMPLETED_ORDER" ] 2>/dev/null; then
        cat <<BLOCK
{
  "decision": "block",
  "reason": "Sections were skipped out of order. These sections are still pending: $PENDING_SECTIONS\n\nYou completed later sections but skipped earlier ones. Go back and run them. The ONLY valid skip reasons are:\n- 'device-only on simulator' — section is marked (device-only) and you're on simulator\n- 'user chose to skip' — user explicitly said to skip\n- 'connection lost after retries' — WDA failed after retry protocol\n\nNOT valid: time constraints, difficulty, 'requires rebuild', 'already tested elsewhere', or any reason you invented."
}
BLOCK
        exit 0
      fi
    fi
  fi
  exit 0
fi

# Check 2: Does the in_progress section have screenshot evidence?
SCREENSHOT_COUNT=$(jq -r --arg s "$CURRENT_SECTION" '
  .sections[$s].screenshots // [] | length
' "$PROGRESS" 2>/dev/null || echo "0")

if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
  cat <<BLOCK
{
  "decision": "block",
  "reason": "No screenshots recorded for section '$CURRENT_SECTION' in progress.json. Every completed section needs screenshots as evidence.\n\n1. Take screenshots at each step (not just SCREENSHOT checkpoints)\n2. Update progress.json with the filenames\n3. Set status to 'completed' in progress.json before completing the task\n\nTo skip instead, set status to 'skipped' with one of these reasons ONLY: 'device-only on simulator', 'user chose to skip', 'connection lost after retries'. No other reasons are valid."
}
BLOCK
  exit 0
fi

# Check 3: Are there pending sections earlier in the order than the current one?
CURRENT_ORDER=$(jq -r --arg s "$CURRENT_SECTION" '
  .expected_order as $order |
  $order | to_entries[] | select(.value == $s) | .key
' "$PROGRESS" 2>/dev/null || echo "999")

EARLIER_PENDING=$(jq -r --arg current_order "$CURRENT_ORDER" '
  .expected_order as $order |
  [.sections | to_entries[]
    | select(.value.status == "pending")
    | .key as $s
    | $order | to_entries[] | select(.value == $s)
    | select((.key | tonumber) < ($current_order | tonumber))
    | .value
  ] | join(", ")
' "$PROGRESS" 2>/dev/null || echo "")

if [ -n "$EARLIER_PENDING" ]; then
  cat <<BLOCK
{
  "decision": "block",
  "reason": "Earlier sections are still pending: $EARLIER_PENDING\n\nYou are completing '$CURRENT_SECTION' but earlier sections haven't been started. Run them in order. The ONLY valid skip reasons are:\n- 'device-only on simulator'\n- 'user chose to skip'\n- 'connection lost after retries'\n\nNOT valid: time constraints, difficulty, 'requires rebuild', 'already tested elsewhere', or any reason you invented. If a section needs setup (JN site, iPad, locale change), do the setup."
}
BLOCK
  exit 0
fi

# All checks passed
exit 0
