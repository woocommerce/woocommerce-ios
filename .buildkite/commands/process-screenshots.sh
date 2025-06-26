#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :apple: Install Native Dependencies"
# Install ImageMagick for screenshot processing
if ! command -v magick &> /dev/null; then
  echo "Installing ImageMagick..."
  brew install imagemagick@7
  brew link imagemagick@7 --force
fi

echo "--- :gem: Install Screenshot Gems"
bundle install --with screenshots

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :gear: Setup Fastlane Dependencies"
bundle exec fastlane run configure_apply

echo "--- :arrow_down: Download Generated Screenshots from CI Artifacts"
cd fastlane
mkdir -p screenshots
# Download all screenshot artifacts from the take-screenshots jobs
buildkite-agent artifact download "fastlane/screenshots-*/**/*" . --step "generate-screenshots"

echo "--- :chart_with_upwards_trend: Generate Screenshot Summary"
bundle exec fastlane create_screenshot_summary

echo "--- :information_source: Check Font Availability"
cd ..
# Check if Proxima Nova is available (should be included in macOS Sonoma and above)
if fc-list | grep -i "proxima" > /dev/null 2>&1; then
  echo "Proxima Nova font found"
elif system_profiler SPFontsDataType | grep -i "proxima" > /dev/null 2>&1; then
  echo "Proxima Nova font found via system_profiler"
else
  echo "Warning: Proxima Nova font not found - promo screenshots may not render correctly"
fi

echo "--- :package: Setup Git LFS"
git lfs install && git lfs fetch && git lfs pull

echo "--- :art: Generate Promo Screenshots"
bundle exec fastlane create_promo_screenshots force:true

echo "--- :arrow_up: Upload Final Screenshots"
buildkite-agent artifact upload "fastlane/screenshots/**/*"
buildkite-agent artifact upload "fastlane/promo_screenshots/**/*"