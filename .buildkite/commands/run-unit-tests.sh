#!/bin/bash -eu

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UNIT_TESTS

echo "--- 📦 Downloading Build Artifacts"
buildkite-agent artifact download build-products.tar .
tar -xf build-products.tar

# Workaround for https://github.com/Automattic/buildkite-ci/issues/79
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🧪 Testing"
bundle exec fastlane test_without_building name:UnitTests
