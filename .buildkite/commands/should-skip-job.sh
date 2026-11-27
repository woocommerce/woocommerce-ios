#!/bin/bash -eu

# Usage: should-skip-job.sh [validation|build|localization|prototype-build]
# validation: For jobs like unit/UI tests, authenticator tests...
#     Skip when changes are limited to documentation, tooling, non-code files, and localization files
# localization: GlotPress extracts strings from source, merges English InfoPlist.strings
#     and uses Fastlane and its gems. Skip only for known documentation and metadata changes.
# build: For jobs building app binaries, e.g. Build, Prototype Builds...
#     Skip when changes are limited to documentation, tooling, and non-code files
#     Does not skip if localization files changed
# prototype-build: Like build, but only on PRs: a trunk prototype is explicitly requested
#
# Prints the reason to skip the job, or `false` to run it. Exits 0 either way, and 15 for invalid arguments.
# `shared-pipeline-vars` exports the result as SKIP_<JOB TYPE>, used as the step's `skip:` (`false` runs the step).
# Webhook PRs and trunk merges can skip jobs. API and trigger builds on trunk can
# supply an ancestor commit in CI_CHANGED_FILES_BASE. Errors and empty diffs run the job.
# CI_FULL_BUILD=1 forces a full run.

run_job() { echo false; exit 0; }

COMMON_PATTERNS=(
  "*.md"
  "*.pot"
  "RELEASE-NOTES.txt"
  "WooCommerce/Resources/release_notes.txt"
  ".gitignore"
  "config/Version.Public.xcconfig"
  "docs/*"
  "fastlane/appstoreres/*"
  "fastlane/helpers/*_test.rb"
  "fastlane/metadata/*"
  "fastlane/screenshots.json"
)

# Check if the job type is valid
job_type="${1:-}"
case "$job_type" in
  validation|build|localization|prototype-build) ;;
  *)
    echo "Error: Job type must be either 'validation', 'build', 'localization', or 'prototype-build'" >&2
    exit 15
    ;;
esac

if [[ "${CI_FULL_BUILD:-}" == 1 || -n "${BUILDKITE_TAG:-}" ]]; then
  run_job
fi
case "${BUILDKITE_SOURCE:-}" in
  webhook) ;;
  api|trigger_job) [[ "${BUILDKITE_PULL_REQUEST-false}" == false && -n "${CI_CHANGED_FILES_BASE:-}" ]] || run_job ;;
  *) run_job ;;
esac

if [[ "${BUILDKITE_PULL_REQUEST-false}" =~ ^[0-9]+$ ]]; then
  changed_files_command=(pr_changed_files)
elif [[ "${BUILDKITE_PULL_REQUEST-false}" == false && "${BUILDKITE_BRANCH:-}" == trunk && "$job_type" != prototype-build ]]; then
  changed_files_command=(check_changed_files)
  if [[ -n "${CI_CHANGED_FILES_BASE:-}" ]]; then
    base_commit=$(git rev-parse --quiet --verify --end-of-options "${CI_CHANGED_FILES_BASE}^{commit}") || run_job
    git merge-base --is-ancestor "$base_commit" HEAD || run_job
    changed_files_command+=(--base "$base_commit")
  else
    # Woo merges PRs with merge commits. Other trunk commits need an explicit base to skip jobs.
    git rev-parse --verify --quiet 'HEAD^2' >/dev/null || run_job
  fi
else
  run_job
fi

if [[ "$job_type" != localization ]]; then
  COMMON_PATTERNS+=("Gemfile" "Gemfile.lock")
fi
if [[ "$job_type" == validation ]]; then
  COMMON_PATTERNS+=("*.strings" "*.stringsdict")
fi
"${changed_files_command[@]}" --all-match "${COMMON_PATTERNS[@]}" || run_job
echo "No relevant files changed"
