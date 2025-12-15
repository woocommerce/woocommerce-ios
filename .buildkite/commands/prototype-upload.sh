#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :firebase: Uploading to Firebase"
bundle exec fastlane upload_prototype_build
