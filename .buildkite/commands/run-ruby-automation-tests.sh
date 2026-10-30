#!/bin/bash -eu

# Runs the Minitest files for our Fastlane helpers
# (fastlane/helpers/*_test.rb). The tests have no Fastlane runtime
# dependency.
#
# Skip behavior lives in `.buildkite/shared-pipeline-vars`, which decides at
# pipeline upload whether this step is part of the build:
# - On PR builds: skipped when no `fastlane/**` files have changed.
# - On non-PR builds (trunk, release branches): always run, so the latest
#   merged state is validated.

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
