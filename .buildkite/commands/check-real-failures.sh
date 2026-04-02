#!/bin/bash -eu

# Determines if the build has real failures worth analyzing with Claude.
#
# "Real failures" exclude:
#   - The "Claude Build Analysis" job (intentional exit 1 to trigger the plugin)
#   - The "Danger" job (external linter, not indicative of build health)
#   - Unnamed/empty jobs (wait steps, group headers)
#
# Exit codes:
#   0 — no real failures (analysis skipped, job stays green)
#   1 — real failures found (triggers Claude analysis via the plugin's on-failure hook)

API_URL="https://api.buildkite.com/v2/organizations/${BUILDKITE_ORGANIZATION_SLUG}/pipelines/${BUILDKITE_PIPELINE_SLUG}/builds/${BUILDKITE_BUILD_NUMBER}"

JOBS_JSON=$(curl -sSf -H "Authorization: Bearer ${BUILDKITE_TOKEN_FOR_CLAUDE}" "${API_URL}" | jq '.jobs')

# Count failed jobs excluding known non-failures
REAL_FAILURE_COUNT=$(echo "${JOBS_JSON}" | jq '
  [.[] | select(
    .state == "failed"
    and ((.name // "") | test("Claude Build Analysis|Danger"; "i") | not)
    and ((.name // "") | length > 0)
  )] | length
')

if [ "${REAL_FAILURE_COUNT}" -gt 0 ]; then
  echo "Found ${REAL_FAILURE_COUNT} real failure(s), triggering Claude analysis"
  exit 1
else
  echo "No real failures found — skipping Claude analysis"
  exit 0
fi
