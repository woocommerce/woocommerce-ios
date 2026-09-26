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

echo "--- :xcode: Linting Xcode Build Settings"
status=0
bundle exec rake lint:xcode_build_settings || status=$?

if [ "$status" -ne 0 ]; then
  # Expand this collapsed log group so reviewers see the violations
  # without having to click into the job.
  # https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  exit "$status"
fi
