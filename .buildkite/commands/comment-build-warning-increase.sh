#!/usr/bin/env bash

set -euo pipefail

# Downloads the current and baseline build warning reports and posts (or
# deletes) the PR comment. The comparison and comment rendering happen in
# compare-build-warnings.rb; this script only orchestrates artifacts and the
# comment_on_pr call.

REPORT_PATH="${1:-build-warnings.json}"
BASELINE_REPORT_PATH="${2:-base-build-warnings.json}"
COMMENT_ID="build-warning-count"
COMMANDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_pull_request() {
  [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]
}

# The reports are dual-uploaded (toolkit S3 store and Buildkite artifacts),
# so a failure of one download method falls back to the other.
download_artifact_path() {
  local artifact_path=$1

  if command -v download_artifact >/dev/null 2>&1 && download_artifact "$artifact_path"; then
    return 0
  fi

  if command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact download "$artifact_path" .
  else
    return 1
  fi
}

download_report() {
  local report_path=$1

  # Reused agent checkouts can contain reports from previous builds; never
  # trust a pre-existing file, always fetch the artifact from this build.
  rm -f "$report_path"
  mkdir -p "$(dirname "$report_path")"

  download_artifact_path "$report_path" || true

  if [ ! -f "$report_path" ] && [ -f "$(basename "$report_path")" ]; then
    mv "$(basename "$report_path")" "$report_path"
  fi

  [ -f "$report_path" ]
}

delete_existing_comment() {
  if command -v comment_on_pr >/dev/null 2>&1; then
    comment_on_pr --id "$COMMENT_ID" --if-exist delete || echo "Failed to delete the existing build warning comment; continuing."
  fi
}

if ! is_pull_request; then
  echo "Not a pull request build; skipping build warning comparison."
  exit 0
fi

if ! download_report "$REPORT_PATH"; then
  echo "No current build warning report artifact found at $REPORT_PATH; skipping comparison."
  delete_existing_comment
  exit 0
fi

if ! download_report "$BASELINE_REPORT_PATH"; then
  echo "No baseline build warning report found at $BASELINE_REPORT_PATH; skipping comparison."
  delete_existing_comment
  exit 0
fi

# Non-fatal: if the comparison crashes outright (interpreter or load failure),
# fall through to the delete-stale-comment path instead of exiting early.
comment_body="$(ruby "$COMMANDS_DIR/compare-build-warnings.rb" "$REPORT_PATH" "$BASELINE_REPORT_PATH")" || comment_body=""

if [ -z "$comment_body" ]; then
  delete_existing_comment
  exit 0
fi

if command -v comment_on_pr >/dev/null 2>&1; then
  comment_on_pr --id "$COMMENT_ID" "$comment_body" || echo "Failed to post the build warning comment."
else
  echo "$comment_body"
fi
