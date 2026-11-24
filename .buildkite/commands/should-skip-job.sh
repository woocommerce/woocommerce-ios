#!/bin/bash -eu

# Usage: should-skip-job.sh [validation|build|localization|prototype-build]
# validation: For jobs like unit/UI tests, authenticator tests...
#     Skip when changes are limited to documentation, tooling, non-code files, and localization files
# localization: For jobs that check localization files
#     Skip when NO localization files have changed
# build: For jobs building app binaries, e.g. Build, Prototype Builds...
#     Skip when changes are limited to documentation, tooling, and non-code files
#     Does not skip if localization files changed
# prototype-build: Like build, but only on PRs: a trunk prototype is explicitly requested
#
# Prints the reason to skip the job, or `false` to run it. Exits 0 either way, and 15 for invalid arguments.
# `shared-pipeline-vars` exports the result as SKIP_<JOB TYPE>, used as the step's `skip:` (`false` runs the step).
# Webhook PRs and trunk merges can skip jobs. Errors and empty diffs run the job.
# Pipeline env: CI_FULL_BUILD=1 forces a full run; CI_CHANGED_FILES_BASE supplies a wider range on trunk.

run_job() { echo false; exit 0; }
skip_job() { echo "$1"; exit 0; }

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

# Check if the job type is valid
job_type="${1:-}"
case "$job_type" in
  validation|build|localization|prototype-build) ;;
  *)
    echo "Error: Job type must be either 'validation', 'build', 'localization', or 'prototype-build'" >&2
    exit 15
    ;;
esac

if [[ "${CI_FULL_BUILD:-}" == 1 || "${BUILDKITE_SOURCE:-}" != webhook || -n "${BUILDKITE_TAG:-}" ]]; then
  run_job
fi

if [[ "${BUILDKITE_PULL_REQUEST-false}" =~ ^[0-9]+$ ]]; then
  changed_files_command=(pr_changed_files)
elif [[ "${BUILDKITE_PULL_REQUEST-false}" == false && "${BUILDKITE_BRANCH:-}" == trunk && "$job_type" != prototype-build ]]; then
  # The pipeline upload step's toolkit may not have check_changed_files yet: run the job.
  command -v check_changed_files >/dev/null 2>&1 || run_job
  changed_files_command=(check_changed_files)
  if [[ -n "${CI_CHANGED_FILES_BASE:-}" ]]; then
    changed_files_command+=(--base "$CI_CHANGED_FILES_BASE")
  else
    # Woo merges PRs with merge commits. Other trunk commits need an explicit base to skip jobs.
    git rev-parse --verify --quiet 'HEAD^2' >/dev/null || run_job
  fi
else
  run_job
fi

case "$job_type" in
  "validation")
    # We should skip if changes are limited to documentation, tooling, non-code files, and localization files
    PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
    "${changed_files_command[@]}" --all-match "${PATTERNS[@]}" || run_job
    skip_job "No relevant files changed"
    ;;
  "localization")
    # We should skip if NO localization files have changed. Errors run the job.
    "${changed_files_command[@]}" || run_job
    localization_changed=$("${changed_files_command[@]}" --stdout --any-match "${LOCALIZATION_PATTERNS[@]}") || run_job
    [[ "$localization_changed" == false ]] || run_job
    skip_job "No localization files changed"
    ;;
  "build"|"prototype-build")
    # We should skip if changes are limited to documentation, tooling, and non-code files
    # We'll let the job run (won't skip) if PR includes changes in localization files though
    PATTERNS=("${COMMON_PATTERNS[@]}")
    "${changed_files_command[@]}" --all-match "${PATTERNS[@]}" || run_job
    skip_job "No relevant files changed"
    ;;
esac
