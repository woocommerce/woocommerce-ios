#!/bin/bash -eu

# Runs pure-Ruby Minitest files for our Fastlane helpers
# (fastlane/helpers/*_test.rb). The tests have no Fastlane runtime
# dependency, so they're cheap to run (<1s total) on the linter queue.
#
# Skip behavior:
# - On PR builds: skip when no `fastlane/**` files have changed.
# - On non-PR builds (trunk, release branches): always run, so the latest
#   merged state is validated.

if [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]; then
  if ! pr_changed_files --any-match 'fastlane/*'; then
    echo "--- :fast_forward: Skipping — no fastlane/ changes in this PR"
    exit 0
  fi
fi

test_files=(fastlane/helpers/*_test.rb)
if [[ ${#test_files[@]} -eq 0 ]] || [[ ! -f "${test_files[0]}" ]]; then
  echo "No fastlane/helpers/*_test.rb files found — nothing to run."
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
