#!/bin/bash -eu

# Uploads the Claude analysis pipeline only when real build/test failures exist.
# Skips Claude when only non-critical jobs failed (e.g. Danger PR check).
#
# Uses buildkite-agent to check known step outcomes. Steps without explicit keys
# can't be checked, but those are rare failure sources.

source .buildkite/shared-pipeline-vars

UPLOAD_NEEDED=false

# If Danger didn't fail, something else caused build.state == "failing"
DANGER_OUTCOME=$(buildkite-agent step get outcome --step danger 2>/dev/null || echo "not_run")
if [ "${DANGER_OUTCOME}" != "failed" ]; then
  UPLOAD_NEEDED=true
fi

# Check critical steps — if any failed, we need Claude regardless of Danger
# Keys that don't exist in this repo will safely return "not_run"
for step_key in build unit-tests build_wordpress build_jetpack; do
  OUTCOME=$(buildkite-agent step get outcome --step "${step_key}" 2>/dev/null || echo "not_run")
  if [ "${OUTCOME}" = "failed" ]; then
    UPLOAD_NEEDED=true
    break
  fi
done

if [ "${UPLOAD_NEEDED}" = true ]; then
  echo "Real failures detected, running Claude analysis"
  buildkite-agent pipeline upload .buildkite/claude-analysis.yml
else
  echo "No real failures detected (only Danger/non-critical jobs), skipping Claude analysis"
fi
