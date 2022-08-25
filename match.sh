#!/bin/bash -eu

# This script runs the same command as the lane that calls `match`.
# The result is the same, 409 error.

bundle exec fastlane match run \
  --type appstore \
  --readonly false \
  --app_identifier com.automattic.woocommerce \
  --template_name 'Apple Pay Pass Suppression' \
  --api_key_path "$HOME/.configure/woocommerce-ios/secrets/app_store_connect_fastlane_api_key.json" \
  --team_id PZYM8XX95Q \
  --storage_mode google_cloud \
  --google_cloud_bucket_name a8c-fastlane-match \
  --google_cloud_keys_file "$HOME/.configure/woocommerce-ios/secrets/google_cloud_keys.json" \
