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

echo "--- :arrow_down: Download Generated Screenshots from S3"
cd fastlane
mkdir -p screenshots
aws s3 cp "s3://${S3_BUCKET}/${BUILDKITE_BUILD_ID}/" screenshots/ --recursive --exclude "*.html"

echo "--- :chart_with_upwards_trend: Generate Screenshot Summary"
bundle exec fastlane create_screenshot_summary
aws s3 cp screenshots/screenshots.html "s3://${S3_BUCKET}/${BUILDKITE_BUILD_ID}/screenshots/screenshots.html"

echo "--- :arrow_down: Install Promo Screenshot Fonts"
cd ..
aws s3 cp "s3://${S3_BUCKET}/fonts.zip" fonts.zip
unzip fonts.zip

# Install fonts system-wide and user-level
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

echo "--- :art: Generate Promo Screenshots"
git lfs install && git lfs fetch && git lfs pull
bundle exec fastlane create_promo_screenshots force:true

echo "--- :arrow_up: Upload Final Screenshots"
buildkite-agent artifact upload "fastlane/screenshots/**/*"
buildkite-agent artifact upload "fastlane/promo_screenshots/**/*"