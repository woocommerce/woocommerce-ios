#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

SECRETS_PATH="${HOME}/.configure/woocommerce-ios/secrets/woo_app_credentials.json"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :closed_lock_with_key: Validating credential keys"
"$(dirname "${BASH_SOURCE[0]}")/validate-credentials.sh"

# Shared Build products must not embed production secrets.
rm -f "${SECRETS_PATH}"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
upload_artifact build-products.tar
