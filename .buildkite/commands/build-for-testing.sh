#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
restore_cache "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
buildkite-agent artifact upload build-products.tar
