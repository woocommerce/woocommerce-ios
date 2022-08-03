#!/bin/bash -eu

CONFIGURATION=$1
DEVICE=$2
IOS_VERSION=$3

echo "Running UI test on $DEVICE for iOS/iPadOS $IOS_VERSION using $CONFIGURATION configuration"

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

echo "--- 🧪 Testing"
xcrun simctl list >> /dev/null
rake mocks &
bundle exec fastlane test_without_building \
  name:UITests \
  configuration:"$CONFIGURATION" \
  device:"$DEVICE" \
  ios_version:"$IOS_VERSION"
