#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

# Check if cached apps exist
if [ -d "fastlane/DerivedData/Build/Products/Debug-iphonesimulator/WooCommerce.app" ] && \
   [ -d "fastlane/DerivedData/Build/Products/Debug-iphonesimulator/WooCommerceScreenshots-Runner.app" ]; then
  echo "--- :white_check_mark: Using Cached Screenshots App"
else
  echo "--- :hammer_and_wrench: Building Screenshots App"
  bundle exec fastlane build_screenshots
fi

echo "--- :package: Create Screenshot App Artifacts"
# Ensure the build products directory exists
if [ ! -d "fastlane/DerivedData/Build/Products/Debug-iphonesimulator" ]; then
  echo "Error: Build products directory not found"
  exit 1
fi

# Create a structured archive of the built apps
tar -cf screenshot-artifacts.tar \
  -C fastlane/DerivedData/Build/Products/Debug-iphonesimulator \
  WooCommerce.app \
  WooCommerceScreenshots-Runner.app

echo "--- :arrow_up: Upload Screenshot App Artifacts"
buildkite-agent artifact upload screenshot-artifacts.tar