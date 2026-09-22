#!/bin/bash -eu

# Strict-concurrency warning baseline guard.
#
# Counts strict-concurrency warnings with SWIFT_STRICT_CONCURRENCY=complete and
# fails if any file exceeds its committed baseline (Scripts/StrictConcurrency/
# baseline.json). Modeled on the former run-periphery.sh baseline pattern.
#
# Runs on every PR. It needs its own clean build, so it does not reuse
# build-products.tar and is the slowest step in the pipeline. The pipeline step
# is soft_fail while the guard is advisory.

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

CURRENT_JSON="strict-concurrency-current.json"

echo '+++ :swift: Counting strict-concurrency warnings'
set +e
./Scripts/StrictConcurrency/count-warnings.sh "$CURRENT_JSON"
COUNT_STATUS=$?
set -e

if [[ $COUNT_STATUS -ne 0 ]]; then
  echo '😱 Warning count failed (build error?) — see log above.'
  if [[ -f strict-concurrency-build-failed.log ]]; then
    buildkite-agent artifact upload strict-concurrency-build-failed.log || true
  fi
  buildkite-agent annotate --context strict-concurrency --style error \
    'Strict-concurrency baseline guard: the measurement build failed, no comparison was possible. Full build log uploaded as artifact `strict-concurrency-build-failed.log`.'
  # The step is soft_fail, so its GitHub status still reports as passed. Say so on the PR,
  # otherwise a broken guard is indistinguishable from a passing one.
  comment_on_pr --id strict-concurrency-guard "## ⚠️ Strict-concurrency baseline guard: measurement build failed

The guard could not measure anything, so no comparison was possible. This does not mean the branch is clean.

Download the \`strict-concurrency-build-failed.log\` artifact from the <a href=\"${BUILDKITE_BUILD_URL}\" target=\"_blank\">build</a> and look for \`error:\` lines. Note that this step is advisory (\`soft_fail\`), so it does not block the merge." \
    || echo 'PR comment failed (not a PR build?) — Buildkite annotation still posted.'
  exit $COUNT_STATUS
fi

# Always publish the fresh counts: the authoritative source for baseline refreshes
# (CI's pinned toolchain is the reference: local Xcode versions can emit a different warning set).
buildkite-agent artifact upload "$CURRENT_JSON" || true

echo '+++ :bar_chart: Comparing against baseline'
COMPARE_OUTPUT_FILE="strict-concurrency-report.txt"
set +e
./Scripts/StrictConcurrency/compare-baseline.sh "$CURRENT_JSON" | tee "$COMPARE_OUTPUT_FILE"
COMPARE_STATUS=${PIPESTATUS[0]}
set -e

if [[ $COMPARE_STATUS -ne 0 ]]; then
  echo '😱 Some files exceed the strict-concurrency baseline.'
  echo '💡 The excess may come from this PR or may already be on trunk (the step is soft_fail). See the PR comment for next steps.'
  (echo "### Files over the strict-concurrency baseline (baseline guard)"; echo ''; echo '```'; cat "$COMPARE_OUTPUT_FILE"; echo '```') \
    | buildkite-agent annotate --context strict-concurrency --style error
  # Surface the failure on the PR itself, Danger-style (idempotent: --id updates the same comment).
  comment_on_pr --id strict-concurrency-guard "## ⚠️ Strict-concurrency baseline guard

These files exceed the committed strict-concurrency baseline (full report in the <a href=\"${BUILDKITE_BUILD_URL}#annotations\" target=\"_blank\">build annotations</a>):

\`\`\`
$(grep -A 100 'FAIL:' "$COMPARE_OUTPUT_FILE")
\`\`\`

The excess may have been introduced by this PR, or it may already be on trunk: the step is advisory (\`soft_fail\`), so a regression can merge and then show up on every PR. Check trunk's latest guard result or the file's history before assuming it is yours.

Next steps:
- If this PR introduced the warnings, fix them in this PR.
- If they were already on trunk, you are encouraged to open a new PR to fix them, or contact the author, creating a Linear issue if necessary.

Fixing can mean changing the code, or raising the affected entries in \`Scripts/StrictConcurrency/baseline.json\` when the increase is justified, so reviewers see it." \
    || echo 'PR comment failed (not a PR build?) — Buildkite annotation still posted.'
else
  buildkite-agent annotate --context strict-concurrency --style success \
    'Strict-concurrency baseline guard: no file exceeds the baseline :tada:'
  # Remove a stale failure comment once the guard passes again.
  comment_on_pr --id strict-concurrency-guard --if-exist delete || true
fi

echo '--- 🚦 Report Exit code'
exit $COMPARE_STATUS
