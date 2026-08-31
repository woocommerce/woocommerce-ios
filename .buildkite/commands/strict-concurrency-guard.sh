#!/bin/bash -eu

# Strict-concurrency warning baseline guard (WOOMOB-3965).
#
# Counts strict-concurrency warnings with SWIFT_STRICT_CONCURRENCY=complete and
# fails if any file exceeds its committed baseline (Scripts/StrictConcurrency/
# baseline.json). Modeled on the former run-periphery.sh baseline pattern.
#
# NOTE: requires a clean build (~25-30 min). Runs per-push only on the
# experimental branch; the production design is a nightly schedule.

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

CURRENT_JSON="strict-concurrency-current.json"

echo '+++ :swift: Counting strict-concurrency warnings'
set +e
./Scripts/StrictConcurrency/count-warnings.sh "$CURRENT_JSON"
COUNT_STATUS=$?
set -e

if [[ $COUNT_STATUS -ne 0 ]]; then
  echo '😱 Warning count failed (build error?) — see log above.'
  buildkite-agent annotate --context strict-concurrency --style error \
    'Strict-concurrency baseline guard: the measurement build failed, no comparison was possible.'
  exit $COUNT_STATUS
fi

echo '+++ :bar_chart: Comparing against baseline'
COMPARE_OUTPUT_FILE="strict-concurrency-report.txt"
set +e
./Scripts/StrictConcurrency/compare-baseline.sh "$CURRENT_JSON" | tee "$COMPARE_OUTPUT_FILE"
COMPARE_STATUS=${PIPESTATUS[0]}
set -e

if [[ $COMPARE_STATUS -ne 0 ]]; then
  echo '😱 New strict-concurrency warnings detected!'
  echo '💡 Fix the new warnings, or — if the increase is genuinely justified — bump the affected counts in Scripts/StrictConcurrency/baseline.json in this PR so reviewers see it.'
  (echo "### New strict-concurrency warnings (baseline guard)"; echo ''; echo '```'; cat "$COMPARE_OUTPUT_FILE"; echo '```') \
    | buildkite-agent annotate --context strict-concurrency --style error
  # Surface the failure on the PR itself, Danger-style (idempotent: --id updates the same comment).
  comment_on_pr --id strict-concurrency-guard "## ⚠️ Strict-concurrency baseline guard

This PR introduces new strict-concurrency warnings (full report in the <a href=\"${BUILDKITE_BUILD_URL}#annotations\" target=\"_blank\">build annotations</a>):

\`\`\`
$(grep -A 100 'FAIL:' "$COMPARE_OUTPUT_FILE")
\`\`\`

Fix the new warnings, or — if the increase is genuinely justified — bump the affected counts in \`Scripts/StrictConcurrency/baseline.json\` in this PR so reviewers see the decision. Context: WOOMOB-3965." \
    || echo 'PR comment failed (not a PR build?) — Buildkite annotation still posted.'
else
  buildkite-agent annotate --context strict-concurrency --style success \
    'Strict-concurrency baseline guard: no file exceeds the baseline :tada:'
  # Remove a stale failure comment once the guard passes again.
  comment_on_pr --id strict-concurrency-guard --if-exist delete || true
fi

echo '--- 🚦 Report Exit code'
exit $COMPARE_STATUS
