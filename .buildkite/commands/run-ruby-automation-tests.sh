#!/bin/bash -eu

# Runs pure-Ruby Minitest files for Fastlane helpers and credentials
# interpolation. The tests have no Fastlane runtime dependency, so they're
# cheap to run (<1s total) on the linter queue.
#
# Skip behavior:
# - On PR builds: skip when none of the tested paths have changed.
# - On non-PR builds (trunk, release branches): always run, so the latest
#   merged state is validated.

if [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]; then
  if ! pr_changed_files --any-match 'fastlane/**' 'WooCommerce/Credentials/**'; then
    echo "--- :fast_forward: Skipping — no fastlane/ or Credentials changes in this PR"
    exit 0
  fi
fi

shopt -s nullglob
test_files=(fastlane/helpers/*_test.rb WooCommerce/Credentials/*_test.rb)
if [[ ${#test_files[@]} -eq 0 ]]; then
  echo "No Ruby automation test files found — nothing to run."
  exit 0
fi

status=0
for f in "${test_files[@]}"; do
  echo "--- :ruby: $f"
  if ! ruby "$f"; then
    status=1
  fi
done

exit "$status"
