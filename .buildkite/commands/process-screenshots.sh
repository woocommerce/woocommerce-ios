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
if system_profiler SPFontsDataType | grep -i "proxima" > /dev/null 2>&1; then
  echo "Proxima Nova font found"
else
  echo "Warning: Proxima Nova font not found - promo screenshots may not render correctly"
  echo "Checking available fonts with 'nova' in name:"
  system_profiler SPFontsDataType | grep -i "nova" | head -5 || echo "No fonts with 'nova' found"
fi

echo "--- :package: Setup Git LFS"
cd ..  # Make sure we're in the repo root
# Install Git LFS if not available
if ! command -v git-lfs &> /dev/null; then
  echo "Installing Git LFS..."
  brew install git-lfs
fi
git lfs install && git lfs fetch && git lfs pull

echo "--- :art: Generate Promo Screenshots"
# Re-setup gems in repo root
install_gems
bundle exec fastlane create_promo_screenshots force:true

echo "--- :arrow_up: Upload Final Screenshots"
buildkite-agent artifact upload "fastlane/screenshots/**/*"
buildkite-agent artifact upload "fastlane/promo_screenshots/**/*"