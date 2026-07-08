#!/bin/bash -eu

set -o pipefail

BASELINE_REPORT_PATH="${1:-base-build-warnings.json}"
BASE_BRANCH="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-trunk}"
SCOPE="owned_app_and_modules"
COMMANDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"

is_pull_request() {
  [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]
}

if ! is_pull_request; then
  echo "Not a pull request build; skipping build warning baseline."
  exit 0
fi

if "$COMMANDS_DIR/should-skip-job.sh" --job-type build; then
  exit 0
fi

echo "--- :git: Resolve build warning baseline"
git fetch --no-tags origin "$BASE_BRANCH"

BASE_REF="origin/$BASE_BRANCH"
BASE_COMMIT="$(git merge-base HEAD "$BASE_REF")"
SHORT_BASE_COMMIT="${BASE_COMMIT:0:12}"
echo "Using $SHORT_BASE_COMMIT as the build warning baseline for $BASE_BRANCH."

mkdir -p "$(dirname "$BASELINE_REPORT_PATH")"

# The counter is the wrapper plus the helper module it delegates to; hash both.
COUNT_SCRIPT_HASH="$(cat "$COMMANDS_DIR/count-build-warnings.rb" "$REPO_ROOT/fastlane/helpers/build_warnings_helper.rb" | shasum | awk '{print $1}')"
BASELINE_SCRIPT_HASH="$(shasum "$COMMANDS_DIR/build-warning-baseline.sh" | awk '{print $1}')"
# The weekly epoch is for storage, not staleness: the key already pins the exact
# base commit, image, and scripts, but rotating keys weekly stops baselines from
# stale/abandoned PRs being kept alive indefinitely in the cache store.
CACHE_EPOCH="${BUILD_WARNING_BASELINE_CACHE_EPOCH:-$(date -u +%Y-W%W)}"
CACHE_KEY_PARTS=("$BASE_COMMIT" "${IMAGE_ID:-unknown-image}" "$SCOPE" "$COUNT_SCRIPT_HASH" "$BASELINE_SCRIPT_HASH" "$CACHE_EPOCH")
CACHE_KEY="$(printf '%s\n' "${CACHE_KEY_PARTS[@]}" | shasum | awk '{print $1}')"
CACHE_DIR="${BUILD_WARNING_BASELINE_CACHE_DIR:-$HOME/.cache/woocommerce-ios/build-warning-baselines}"
CACHE_PATH="$CACHE_DIR/$CACHE_KEY.json"

# Key rotation alone never deletes files on the agent, so prune local entries
# past two epochs to keep the cache directory bounded.
if [ -d "$CACHE_DIR" ]; then
  find "$CACHE_DIR" -type f -name '*.json' -mtime +14 -delete 2>/dev/null || true
fi
TOOLKIT_CACHE_KEY="build-warning-baseline-$CACHE_KEY"
TOOLKIT_CACHE_DIR="${BUILD_WARNING_BASELINE_TOOLKIT_CACHE_DIR:-build-warning-baseline-cache}"
TOOLKIT_CACHE_PATH="$TOOLKIT_CACHE_DIR/base-build-warnings.json"

if [[ "$BASELINE_REPORT_PATH" = /* ]]; then
  ABSOLUTE_BASELINE_REPORT_PATH="$BASELINE_REPORT_PATH"
else
  ABSOLUTE_BASELINE_REPORT_PATH="$REPO_ROOT/$BASELINE_REPORT_PATH"
fi

cache_matches_baseline() {
  local report_path=$1
  jq -e \
    --arg base_commit "$BASE_COMMIT" \
    --arg scope "$SCOPE" \
    '.baseline_commit == $base_commit and .scope == $scope and (.count | type == "number")' \
    "$report_path" >/dev/null
}

upload_baseline_artifact() {
  if command -v upload_artifact >/dev/null 2>&1; then
    upload_artifact "$BASELINE_REPORT_PATH" || true
  fi

  if command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact upload "$BASELINE_REPORT_PATH" || true
  fi
}

copy_to_baseline_report() {
  local report_path=$1

  cp "$report_path" "$BASELINE_REPORT_PATH"
}

annotate_baseline_source() {
  local source=$1
  local baseline_report_tmp

  baseline_report_tmp="$(mktemp)"
  jq \
    --arg source "$source" \
    '. + {baseline_cache_source: $source}' \
    "$BASELINE_REPORT_PATH" > "$baseline_report_tmp"
  mv "$baseline_report_tmp" "$BASELINE_REPORT_PATH"
}

save_toolkit_cache() {
  if ! command -v save_cache >/dev/null 2>&1; then
    return
  fi

  rm -rf "$TOOLKIT_CACHE_DIR"
  mkdir -p "$TOOLKIT_CACHE_DIR"
  cp "$BASELINE_REPORT_PATH" "$TOOLKIT_CACHE_PATH"
  save_cache "$TOOLKIT_CACHE_DIR" "$TOOLKIT_CACHE_KEY" || true
  rm -rf "$TOOLKIT_CACHE_DIR"
}

restore_toolkit_cache() {
  if ! command -v restore_cache >/dev/null 2>&1; then
    return 1
  fi

  rm -rf "$TOOLKIT_CACHE_DIR"
  restore_cache "$TOOLKIT_CACHE_KEY" || return 1

  if [ -f "$TOOLKIT_CACHE_PATH" ] && cache_matches_baseline "$TOOLKIT_CACHE_PATH"; then
    return 0
  fi

  rm -rf "$TOOLKIT_CACHE_DIR"
  return 1
}

if [ -f "$CACHE_PATH" ] && cache_matches_baseline "$CACHE_PATH"; then
  echo "Reusing local cached build warning baseline for $SHORT_BASE_COMMIT."
  copy_to_baseline_report "$CACHE_PATH"
  annotate_baseline_source "local-cache"
  save_toolkit_cache
  upload_baseline_artifact
  exit 0
fi

if restore_toolkit_cache; then
  echo "Reusing shared cached build warning baseline for $SHORT_BASE_COMMIT."
  mkdir -p "$CACHE_DIR"
  cp "$TOOLKIT_CACHE_PATH" "$CACHE_PATH"
  copy_to_baseline_report "$TOOLKIT_CACHE_PATH"
  annotate_baseline_source "shared-cache"
  rm -rf "$TOOLKIT_CACHE_DIR"
  upload_baseline_artifact
  exit 0
fi

BASE_WORKTREE="$(mktemp -d "${TMPDIR:-/tmp}/woo-warning-base.XXXXXX")"
rm -rf "$BASE_WORKTREE"

cleanup() {
  # Leave the worktree before removing it: `git worktree remove` run from
  # inside the tree falls back to `rm -rf`, orphaning .git/worktrees metadata.
  cd "$REPO_ROOT"
  git worktree remove --force "$BASE_WORKTREE" 2>/dev/null || rm -rf "$BASE_WORKTREE"
}
trap cleanup EXIT

git worktree prune
git worktree add --detach "$BASE_WORKTREE" "$BASE_COMMIT"

pushd "$BASE_WORKTREE"

"$BASE_WORKTREE/.buildkite/commands/shared-set-up.sh"

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env
rm -rf fastlane/logs

echo "--- :hammer_and_wrench: Building baseline"
SCAN_BUILDLOG_PATH="$BASE_WORKTREE/fastlane/logs" bundle exec fastlane build_for_testing

echo "--- :warning: Count baseline build warnings"
BUILDKITE_BUILD_CHECKOUT_PATH="$BASE_WORKTREE" ruby "$COMMANDS_DIR/count-build-warnings.rb" fastlane/logs "$ABSOLUTE_BASELINE_REPORT_PATH"

popd

baseline_report_tmp="$(mktemp)"
jq \
  --arg base_branch "$BASE_BRANCH" \
  --arg base_commit "$BASE_COMMIT" \
  --arg baseline_cache_source "rebuilt" \
  '. + {base_branch: $base_branch, baseline_commit: $base_commit, baseline_cache_source: $baseline_cache_source}' \
  "$BASELINE_REPORT_PATH" > "$baseline_report_tmp"
mv "$baseline_report_tmp" "$BASELINE_REPORT_PATH"

mkdir -p "$CACHE_DIR"
cp "$BASELINE_REPORT_PATH" "$CACHE_PATH"

save_toolkit_cache
upload_baseline_artifact
