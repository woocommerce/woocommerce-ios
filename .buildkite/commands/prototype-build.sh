#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_prototype_build
