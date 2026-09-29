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
BUILD_COMMIT="${BUILDKITE_PULL_REQUEST_HEAD_COMMIT:-${BUILDKITE_COMMIT:-}}"

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

is_current_head() {
  local repository="${BUILDKITE_REPO:-}"
  repository="${repository#git@github.com:}"
  repository="${repository#https://github.com/}"
  repository="${repository%.git}"

  if [[ ! "$repository" =~ ^[[:alnum:]_.-]+/[[:alnum:]_.-]+$ ]] || [[ ! "$BUILD_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Cannot identify the built PR commit; leaving the existing comment unchanged."
    return 1
  fi

  local current_head
  if ! current_head="$(github_api "repos/$repository/pulls/$BUILDKITE_PULL_REQUEST" --fail --connect-timeout 10 --max-time 30 |
    jq -er '.head.sha | select(type == "string" and test("^[0-9a-f]{40}$"))')"; then
    echo "Cannot verify the current PR head; leaving the existing comment unchanged."
    return 1
  fi

  if [ "$current_head" != "$BUILD_COMMIT" ]; then
    echo "This build is no longer the current PR head; leaving the existing comment unchanged."
    return 1
  fi
}

unavailable_comment() {
  printf '## Build warning comparison unavailable\n\n%s\n\n' "$1"
  printf 'No conclusion about new warnings could be reached. See the [CI build](%s) for details.\n' "${BUILDKITE_BUILD_URL:-}"
}

if ! is_pull_request; then
  echo "Not a pull request build; skipping build warning comparison."
  exit 0
fi

if "$COMMANDS_DIR/should-skip-job.sh" --job-type build; then
  exit 0
fi

if ! download_report "$REPORT_PATH"; then
  comment_body="$(unavailable_comment 'The current build warning report is missing.')"
elif ! download_report "$BASELINE_REPORT_PATH"; then
  comment_body="$(unavailable_comment 'The baseline build warning report is missing.')"
elif ! comment_body="$(ruby "$COMMANDS_DIR/compare-build-warnings.rb" "$REPORT_PATH" "$BASELINE_REPORT_PATH")"; then
  comment_body="$(unavailable_comment 'The build warning reports could not be compared.')"
fi

if ! command -v comment_on_pr >/dev/null 2>&1; then
  echo "$comment_body"
  exit 0
fi

# Check immediately before either mutation so an older retried build cannot
# knowingly replace the result for a newer PR head.
if ! is_current_head; then
  exit 0
fi

if [ -z "$comment_body" ]; then
  comment_on_pr --id "$COMMENT_ID" --if-exist delete || echo "Failed to delete the existing build warning comment; continuing."
else
  comment_body+=$'\n\n'"Built commit: \`$BUILD_COMMIT\`."
  comment_on_pr --id "$COMMENT_ID" "$comment_body" || echo "Failed to post the build warning comment."
fi
