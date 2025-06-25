#!/bin/bash -eu

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

echo "--- :information_source: Debug Environment Variables"
echo "SCREENSHOT_LANGUAGE: '${SCREENSHOT_LANGUAGE:-NOT_SET}'"
echo "SCREENSHOT_MODE: '${SCREENSHOT_MODE:-NOT_SET}'"

echo "--- :camera: Generate Screenshots for ${SCREENSHOT_LANGUAGE:-unknown} (${SCREENSHOT_MODE:-unknown} mode)"
bundle exec fastlane take_screenshots \
  languages:"${SCREENSHOT_LANGUAGE:-en-US}" \
  mode:"${SCREENSHOT_MODE:-light}"

echo "--- :arrow_up: Upload Screenshots to S3"
# Create unique directory for this job's screenshots
SCREENSHOT_DIR="fastlane/screenshots-${SCREENSHOT_LANGUAGE:-en-US}-${SCREENSHOT_MODE:-light}"
if [ -d "fastlane/screenshots" ]; then
  mv fastlane/screenshots "${SCREENSHOT_DIR}"
  aws s3 cp "${SCREENSHOT_DIR}" "s3://${S3_BUCKET}/${BUILDKITE_BUILD_ID}/screenshots-${SCREENSHOT_LANGUAGE:-en-US}-${SCREENSHOT_MODE:-light}/" --recursive --exclude "*.html"
fi