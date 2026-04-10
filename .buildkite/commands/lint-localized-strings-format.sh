#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type localization; then
  exit 0
fi

echo "--- :writing_hand: Copy Files"
SECRETS_DIR=~/.configure/woocommerce-ios/secrets
mkdir -pv $SECRETS_DIR
cp -v fastlane/env/project.env.example $SECRETS_DIR/project.env

lint_localized_strings_format
