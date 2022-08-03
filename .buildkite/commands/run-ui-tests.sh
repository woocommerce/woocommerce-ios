#!/bin/bash -eu

TEST_NAME=$1
DEVICE=$2
IOS_VERSION=$3

echo "Running $TEST_NAME on $DEVICE for iOS $IOS_VERSION"

# Workaround for https://github.com/Automattic/buildkite-ci/issues/79
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler

# FIXIT-13.1: Temporary fix until all VMs have a JVM
brew install openjdk@11
sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

echo "--- 📦 Downloading Build Artifacts"
buildkite-agent artifact download build-products.tar .
tar -xf build-products.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- Configure Test Analytics"
# Collect data separately for iPhone and iPad
if [[ $DEVICE =~ ^iPhone ]]; then
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPHONE
else
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPAD
fi

echo "BUILDKITE_ANALYTICS_TOKEN starts with $(echo $BUILDKITE_ANALYTICS_TOKEN | cut -c1-5)"

echo "--- 🧪 Testing"
xcrun simctl list >> /dev/null
rake mocks &
bundle exec fastlane test_without_building name:"$TEST_NAME" device:"$DEVICE" ios_version:"$IOS_VERSION"
