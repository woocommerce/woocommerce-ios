#!/bin/bash -eu

echo "--- :writing_hand: Copy Files"
SECRETS_DIR=~/.configure/woocommerce-ios/secrets
mkdir -pv $SECRETS_DIR
cp -v fastlane/env/project.env.example $SECRETS_DIR/project.env

echo "--- :swift: Restoring SPM Cache"
install_swiftpm_dependencies

lint_localized_strings_format
