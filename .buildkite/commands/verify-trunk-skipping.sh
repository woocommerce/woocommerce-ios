#!/bin/bash
set -euo pipefail

# Verification PRs only. The fixture commits follow the pipeline/script commit,
# so the tested ranges contain only the docs or code changes under test.
scenario=${1:?Pass docs or code-docs}
skip_script=.buildkite/commands/should-skip-job.sh
checks=0

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_decision() {
  local expected=$1 job_type=$2 actual
  if /bin/bash -eu "$skip_script" --job-type "$job_type"; then
    actual=0
  else
    actual=$?
  fi
  [[ "$actual" == "$expected" ]] || fail "$job_type returned $actual; expected $expected"
  echo "PASS: $job_type returned $actual (0=skip, 1=run)"
  checks=$((checks + 1))
}

assert_all_run() {
  assert_decision 1 build
  assert_decision 1 validation
  assert_decision 1 localization
}

echo "--- Real toolkit helper"
command -v commit_changed_files
echo "Actual CI branch: ${BUILDKITE_BRANCH:-unset}; PR: ${BUILDKITE_PULL_REQUEST:-unset}"

echo "--- Check fixture history"
last_files=$(git diff-tree -r --name-only HEAD^ HEAD)
[[ "$last_files" == README.md ]] || fail 'the latest commit must only change README.md'
case "$scenario" in
  docs)
    range_base=HEAD^
    ;;
  code-docs)
    range_base=HEAD~2
    range_files=$(git diff-tree -r --name-only "$range_base" HEAD)
    expected_files=$'README.md\nWooCommerce/Classes/System/ProcessConfiguration.swift'
    [[ "$range_files" == "$expected_files" ]] || fail 'the wider range must contain only Swift and README changes'
    ;;
  *) fail "Unknown scenario: $scenario" ;;
esac

# Only this process and its children see the simulated trunk context. The actual
# Buildkite build remains a PR build, with its original branch and GitHub status.
export BUILDKITE_SOURCE=webhook BUILDKITE_BRANCH=trunk BUILDKITE_PULL_REQUEST=false
unset BUILDKITE_TAG CI_FULL_BUILD CI_CHANGED_FILES_BASE

echo "--- Trunk default: latest commit is docs-only"
assert_decision 0 build
assert_decision 0 validation
assert_decision 0 localization

echo "--- Real job entry points must return before build/test setup"
for script in build-for-testing run-unit-tests strict-concurrency-guard lint-localized-strings-format; do
  output=$(/bin/bash -eu ".buildkite/commands/$script.sh")
  echo "$output"
  [[ "$output" == *Skipping* ]] || fail "$script did not report a skip"
  checks=$((checks + 1))
done
for device in 'iPhone 17' 'iPad Pro 13-inch (M5)'; do
  output=$(/bin/bash -eu .buildkite/commands/run-ui-tests.sh UITests "$device")
  echo "$output"
  [[ "$output" == *Skipping* ]] || fail "UI tests on $device did not report a skip"
  checks=$((checks + 1))
done

echo "--- Explicit base HEAD^ must still skip docs-only changes"
export CI_CHANGED_FILES_BASE=HEAD^
assert_decision 0 build
assert_decision 0 validation
assert_decision 0 localization

if [[ "$scenario" == code-docs ]]; then
  echo "--- Explicit wider base: $range_base"
  export CI_CHANGED_FILES_BASE="$range_base"
  assert_decision 1 build
  assert_decision 1 validation
  assert_decision 0 localization
fi

echo "--- Invalid base must run every job"
export CI_CHANGED_FILES_BASE=refs/heads/ci-probe-base-that-does-not-exist
assert_all_run
unset CI_CHANGED_FILES_BASE

echo "--- Full-build override must run every job"
export CI_FULL_BUILD=1
assert_all_run
unset CI_FULL_BUILD

for build_source in api ui schedule; do
  echo "--- $build_source builds must run every job"
  export BUILDKITE_SOURCE="$build_source"
  assert_all_run
done

echo "--- Release branches and tags must run every job"
export BUILDKITE_SOURCE=webhook BUILDKITE_BRANCH=release/ci-probe
assert_all_run
export BUILDKITE_BRANCH=trunk BUILDKITE_TAG=ci-probe
assert_all_run

echo "PASS: $checks checks for $scenario, using the real toolkit and skip script"
