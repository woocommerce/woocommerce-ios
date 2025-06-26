#!/bin/bash -eu

# Get matrix values from command arguments
SCREENSHOT_LANGUAGE="${1:-en-US}"
SCREENSHOT_MODE="${2:-light}"

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :arrow_down: Download Screenshot App Artifacts"
buildkite-agent artifact download screenshot-artifacts.tar . --job "build-screenshots"
mkdir -p fastlane/DerivedData/Build/Products/Debug-iphonesimulator/
tar -xf screenshot-artifacts.tar -C fastlane/DerivedData/Build/Products/Debug-iphonesimulator/

echo "--- :gear: Setup Fastlane Dependencies"
bundle exec fastlane run configure_apply

echo "--- :information_source: Screenshot Configuration"
echo "SCREENSHOT_LANGUAGE: '${SCREENSHOT_LANGUAGE}'"
echo "SCREENSHOT_MODE: '${SCREENSHOT_MODE}'"

echo "--- :camera: Generate Screenshots for ${SCREENSHOT_LANGUAGE} (${SCREENSHOT_MODE} mode)"
bundle exec fastlane take_screenshots \
  languages:"${SCREENSHOT_LANGUAGE}" \
  mode:"${SCREENSHOT_MODE}"

echo "--- :arrow_up: Upload Screenshots as CI Artifacts"
# Create unique directory for this job's screenshots
SCREENSHOT_DIR="fastlane/screenshots-${SCREENSHOT_LANGUAGE}-${SCREENSHOT_MODE}"
if [ -d "fastlane/screenshots" ]; then
  mv fastlane/screenshots "${SCREENSHOT_DIR}"
  # Upload as Buildkite artifacts for later processing
  buildkite-agent artifact upload "${SCREENSHOT_DIR}/**/*" --job "${BUILDKITE_JOB_ID}"
fi