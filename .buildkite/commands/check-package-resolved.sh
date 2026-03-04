#!/bin/bash -eu

echo '--- :swift: Ensure single Package.resolved'

FORBIDDEN_PATH="WooCommerce.xcworkspace/xcshareddata/swiftpm/Package.resolved"
EXPECTED_PATH="Modules/Package.resolved"

if [ -f "$FORBIDDEN_PATH" ]; then
  echo "^^^ +++"
  echo "Found resolved file at '$FORBIDDEN_PATH'."
  echo ''
  echo "This should never happen. The only resolved file should be at $EXPECTED_PATH."
  echo ''
  echo "Find more details at https://github.com/woocommerce/woocommerce-ios/pull/16640"
  exit 1
fi

echo "[Good] No resolved file found at '$FORBIDDEN_PATH'."

if [ ! -f "$EXPECTED_PATH" ]; then
  echo "^^^ +++"
  echo "Expected resolved file at '$EXPECTED_PATH' not found."
  echo ''
  echo "This file must be checked in to ensure reproducible builds."
  echo ''
  echo "Find more details at https://github.com/woocommerce/woocommerce-ios/pull/16640"
  exit 1
fi

echo "[Good] Resolved file found at '$EXPECTED_PATH' as expected."
