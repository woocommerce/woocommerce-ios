#!/bin/bash -eu

# Usage: should-skip-job.sh --job-type [validation|build|localization]
# --job-type validation: For jobs like unit/UI tests, authenticator tests...
#     Skip when changes are limited to documentation, tooling, non-code files, and localization files
# --job-type localization: For jobs that check localization files
#     Check if any localization files have changed
#     Return true (skip) if NO localization files have changed
# --job-type build: For jobs building app binaries, e.g. Build, Prototype Builds...
#     Skip when changes are limited to documentation, tooling, and non-code files
#     Does not skip if localization files changed
#
# Return codes:
# 0 - Job should be skipped (script also handles displaying the message and annotation)
# 1 - Job should not be skipped
# 15 - Error in script parameters
#
# Webhook PR and trunk builds can skip jobs. trunk compares HEAD with its first parent.
# Job/pipeline env: CI_FULL_BUILD=1 forces a full run; CI_CHANGED_FILES_BASE supplies a wider range.

COMMON_PATTERNS=(
  "*.md"
  "*.pot"
  "*.txt"
  ".gitignore"
  "config/Version.Public.xcconfig"
  "docs/**"
  "fastlane/**"
  "Gemfile"
  "Gemfile.lock"
)

LOCALIZATION_PATTERNS=(
  "**/*.strings"
  "**/*.stringsdict"
)

# Check if arguments are valid
if [ -z "${1:-}" ] || [ "$1" != "--job-type" ] || [ -z "${2:-}" ]; then
  echo "Error: Must specify --job-type [validation|build|localization]"
  buildkite-agent step cancel
  exit 15
fi

job_type="$2"
case "$job_type" in
  validation|build|localization) ;;
  *)
    echo "Error: Job type must be either 'validation', 'build', or 'localization'"
    buildkite-agent step cancel
    exit 15
    ;;
esac

if [[ "${CI_FULL_BUILD:-}" == 1 || "${BUILDKITE_SOURCE:-}" != webhook || -n "${BUILDKITE_TAG:-}" ]]; then
  exit 1
fi

if [[ "${BUILDKITE_PULL_REQUEST-false}" =~ ^[0-9]+$ ]]; then
  changed_files=(pr_changed_files)
elif [[ "${BUILDKITE_PULL_REQUEST-false}" == false && "${BUILDKITE_BRANCH:-}" == trunk ]]; then
  changed_files=(commit_changed_files)
  if [[ -n "${CI_CHANGED_FILES_BASE:-}" ]]; then
    changed_files+=(--base "$CI_CHANGED_FILES_BASE")
  fi
else
  exit 1
fi

# Function to display skip message and create annotation
show_skip_message() {
  local job_type=$1
  local message="Skipping ${BUILDKITE_LABEL:-Job} - no relevant files changed"
  local context="skip-$(echo "${BUILDKITE_LABEL:-$job_type}" | sed -E -e 's/[^[:alnum:]]+/-/g' | tr A-Z a-z)"
  
  echo "$message" | buildkite-agent annotate --style "info" --context "$context"
  echo "$message"
}

case "$job_type" in
  "validation")
    # We should skip if changes are limited to documentation, tooling, non-code files, and localization files
    PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
    if "${changed_files[@]}" --all-match "${PATTERNS[@]}"; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
  "localization")
    # Check if any localization files have changed
    # Return true (skip) if NO localization files have changed
    localization_changed=$("${changed_files[@]}" --stdout --any-match "${LOCALIZATION_PATTERNS[@]}") || exit 1
    if [[ "$localization_changed" == false ]]; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
  "build")
    # We should skip if changes are limited to documentation, tooling, and non-code files
    # We'll let the job run (won't skip) if PR includes changes in localization files though
    PATTERNS=("${COMMON_PATTERNS[@]}")
    if "${changed_files[@]}" --all-match "${PATTERNS[@]}"; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
esac
