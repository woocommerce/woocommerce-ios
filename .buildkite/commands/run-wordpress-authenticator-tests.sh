#!/bin/bash

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  message="Skipping WordPressAuthenticator Unit Tests - no relevant files changed"
  echo "$message" | buildkite-agent annotate --style "info" --context "skip-wp-auth-tests"
  echo "$message"
  exit 0
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- 🧪 Testing"
bundle exec fastlane run scan \
  scheme:WordPressAuthenticator \
  prelaunch_simulator:true \
  device:'iPhone 16' 