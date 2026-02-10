#!/bin/bash

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- 🧪 Testing"
bundle exec fastlane run scan \
  scheme:WordPressAuthenticator \
  prelaunch_simulator:true \
  device:'iPhone 16' 
