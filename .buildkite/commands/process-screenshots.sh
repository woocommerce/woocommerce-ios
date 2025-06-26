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
buildkite-agent artifact download "fastlane/screenshots-*/**/*" . --step "take-screenshots"

echo "--- :chart_with_upwards_trend: Generate Screenshot Summary"
bundle exec fastlane create_screenshot_summary

echo "--- :arrow_down: Install Promo Screenshot Fonts"
cd ..
# Download fonts from artifacts (assuming fonts are uploaded as artifacts in a separate step)
buildkite-agent artifact download "fonts.zip" . --step "prepare-fonts" || echo "No fonts artifact found, continuing without promo fonts"
if [ -f "fonts.zip" ]; then
  unzip fonts.zip
fi

# Install fonts system-wide and user-level (only if fonts exist)
if [ -d "fonts" ] && [ "$(ls -A fonts/*.otf 2>/dev/null)" ]; then
  mkdir -p ~/Library/Fonts
  cp -v fonts/*.otf ~/Library/Fonts
  ls ~/Library/Fonts

  mkdir -p /Library/Fonts
  sudo cp -v fonts/*.otf /Library/Fonts
  ls /Library/Fonts

  # Reset the font server to recognize new fonts
  atsutil databases -removeUser
  atsutil server -shutdown
  atsutil server -ping
else
  echo "No fonts found, skipping font installation"
fi

echo "--- :art: Generate Promo Screenshots"
git lfs install && git lfs fetch && git lfs pull
bundle exec fastlane create_promo_screenshots force:true

echo "--- :arrow_up: Upload Final Screenshots"
buildkite-agent artifact upload "fastlane/screenshots/**/*"
buildkite-agent artifact upload "fastlane/promo_screenshots/**/*"