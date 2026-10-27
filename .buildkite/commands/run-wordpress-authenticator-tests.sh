#!/bin/bash

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- 🧪 Testing"
# Reuse the packages that shared-set-up.sh resolved into Modules/.build instead of checking them out again.
bundle exec fastlane run scan \
  scheme:WordPressAuthenticator \
  prelaunch_simulator:true \
  cloned_source_packages_path:Modules/.build \
  device:'iPhone 16'
