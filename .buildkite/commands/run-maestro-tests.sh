#!/bin/bash -eu

# Maestro Smoke Tests Runner for Buildkite CI
#
# Prerequisites:
#   - MAESTRO_WOO_EMAIL, MAESTRO_WOO_PASSWORD, MAESTRO_WOO_STORE_URL set as pipeline env vars
#   - Build artifacts available (build-products.tar)
#   - Java 17+ installed on the agent

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- 🔧 Installing Maestro"
if ! command -v maestro &> /dev/null; then
  curl -fsSL "https://get.maestro.mobile.dev" | bash
  export PATH="$HOME/.maestro/bin:$PATH"
fi
maestro --version

echo "--- 🚀 Booting Simulator"
DEVICE="iPhone 16"
xcrun simctl list >> /dev/null
xcrun simctl boot "$DEVICE" 2>/dev/null || true

# Wait for the simulator to be fully booted
echo "⏳ Waiting for Simulator to be Ready"
while ! xcrun simctl list | grep "$DEVICE" | grep "Booted"; do
  echo "Waiting for $DEVICE to boot..."
  sleep 2
done
echo "✅ Simulator is Ready"

echo "--- 📱 Installing App"
# Find and install the built app
APP_PATH=$(find . -name "WooCommerce.app" -path "*/Debug-iphonesimulator/*" | head -1)
if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find WooCommerce.app in build artifacts"
  exit 1
fi
xcrun simctl install booted "$APP_PATH"

echo "--- 🧪 Running Maestro Smoke Tests"
set +e
maestro test \
  --format junit \
  --output .maestro/report.xml \
  --include-tags=smoke \
  .maestro/
TESTS_EXIT_STATUS=$?
set -e

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Maestro smoke tests passed ✅"
else
  echo "^^^ +++"
  echo "Maestro smoke tests failed!"
fi

exit $TESTS_EXIT_STATUS
