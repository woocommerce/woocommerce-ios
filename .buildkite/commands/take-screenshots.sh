#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :arrow_down: Download Screenshot App Artifacts"
buildkite-agent artifact download screenshot-artifacts.tar . --job "build-app-for-screenshots"
tar -xf screenshot-artifacts.tar -C fastlane/DerivedData/Build/Products/Debug-iphonesimulator/

echo "--- :gear: Setup Fastlane Dependencies"
bundle exec fastlane run configure_apply

echo "--- :camera: Generate Screenshots for ${SCREENSHOT_LANGUAGE} (${SCREENSHOT_MODE} mode)"
bundle exec fastlane take_screenshots \
  languages:"${SCREENSHOT_LANGUAGE}" \
  mode:"${SCREENSHOT_MODE}"

echo "--- :arrow_up: Upload Screenshots to S3"
# Create unique directory for this job's screenshots
SCREENSHOT_DIR="fastlane/screenshots-${SCREENSHOT_LANGUAGE}-${SCREENSHOT_MODE}"
if [ -d "fastlane/screenshots" ]; then
  mv fastlane/screenshots "${SCREENSHOT_DIR}"
  aws s3 cp "${SCREENSHOT_DIR}" "s3://${S3_BUCKET}/${BUILDKITE_BUILD_ID}/screenshots-${SCREENSHOT_LANGUAGE}-${SCREENSHOT_MODE}/" --recursive --exclude "*.html"
fi