#!/bin/bash -eu

# Usage: should-skip-job.sh --job-type [validation|build|localization]
# --job-type validation: For jobs like unit/UI tests, authenticator tests...
#     Skip when changes are limited to documentation, tooling, non-code files, and localization files
# --job-type localization: For jobs that check localization files
#     Skip when NO localization files have changed, and outside pull requests
# --job-type build: For jobs building app binaries, e.g. Build, Prototype Builds...
#     Skip when changes are limited to documentation, tooling, and non-code files
#     Does not skip if localization files changed
#
# Prints the reason to skip the job, or `false` to run it. Exits 0 either way, and 15 for invalid arguments.
# `shared-pipeline-vars` exports the result as SKIP_<JOB TYPE>, used as the step's `skip:` (`false` runs the step).
# Only PR builds skip validation and build jobs. Errors and empty diffs run the job.

run_job() { echo false; exit 0; }

COMMON_PATTERNS=(
  "*.md"
  "*.pot"
  "*.txt"
  ".gitignore"
  "config/Version.Public.xcconfig"
  "docs/**"
  "fastlane/appstoreres/*"
  "fastlane/helpers/*_test.rb"
  "fastlane/metadata/*"
  "fastlane/screenshots.json"
  "Gemfile"
  "Gemfile.lock"
)

LOCALIZATION_PATTERNS=(
  "**/*.strings"
  "**/*.stringsdict"
)

# Check if arguments are valid
if [[ $# -ne 2 || "$1" != "--job-type" ]]; then
  echo "Error: Must specify --job-type [validation|build|localization]" >&2
  exit 15
fi
job_type="$2"
case "$job_type" in
  validation|build|localization) ;;
  *)
    echo "Error: Job type must be either 'validation', 'build', or 'localization'" >&2
    exit 15
    ;;
esac

if [[ ! "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]; then
  # As before, the localization check only runs for PRs that change localization files.
  if [[ "$job_type" == localization ]]; then
    echo "Not a pull request"
    exit 0
  fi
  run_job
fi

case "$job_type" in
  "validation")
    # We should skip if changes are limited to documentation, tooling, non-code files, and localization files
    PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
    pr_changed_files --all-match "${PATTERNS[@]}" || run_job
    echo "No relevant files changed"
    ;;
  "localization")
    # We should skip if NO localization files have changed. Errors run the job.
    pr_changed_files || run_job
    localization_changed=$(pr_changed_files --stdout --any-match "${LOCALIZATION_PATTERNS[@]}") || run_job
    [[ "$localization_changed" == false ]] || run_job
    echo "No localization files changed"
    ;;
  "build")
    # We should skip if changes are limited to documentation, tooling, and non-code files
    # We'll let the job run (won't skip) if PR includes changes in localization files though
    PATTERNS=("${COMMON_PATTERNS[@]}")
    pr_changed_files --all-match "${PATTERNS[@]}" || run_job
    echo "No relevant files changed"
    ;;
esac
