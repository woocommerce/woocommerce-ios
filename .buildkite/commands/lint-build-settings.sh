#!/usr/bin/env bash

set -eu

echo "--- :rubygems: Setting up Gems"
install_gems

# `lint:xcode_build_settings` runs a SwiftPM tool from `BuildSettingsPolice/`.
# Resolve its dependencies up front so the Buildkite cache can pick them up
# and subsequent runs check out the repo fast.
echo "--- :swift: Setting up Swift Packages"
pushd "$(dirname "${BASH_SOURCE[0]}")/../../BuildSettingsPolice"
install_swiftpm_dependencies
popd

echo "--- :sleuth_or_spy: Linting Xcode Build Settings"
bundle exec rake lint:xcode_build_settings
