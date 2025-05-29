#!/bin/bash

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- 🧪 Testing"
bundle exec fastlane run scan \
  scheme:WordPressAuthenticator \
  prelaunch_simulator:true \
  device:'iPhone 16' 
