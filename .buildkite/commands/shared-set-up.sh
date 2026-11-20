#!/usr/bin/env bash

set -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
restore_swiftpm_cache --package-resolved Modules/Package.resolved "$@"
