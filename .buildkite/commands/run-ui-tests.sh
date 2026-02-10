#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

TEST_NAME=$1
DEVICE=$2

echo "Running $TEST_NAME on $DEVICE"

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
if [[ $DEVICE =~ ^iPhone ]]; then
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPHONE
else
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPAD
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :keyboard: Connecting Hardware Keyboard"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool true

echo "--- 🚀 Booting Simulator"
xcrun simctl list >> /dev/null
xcrun simctl boot "$DEVICE"

# Wait for the simulator to be fully booted
echo "⏳ Waiting for Simulator to be Ready"
while ! xcrun simctl list | grep "$DEVICE" | grep "Booted"; do
  echo "Waiting for $DEVICE to boot..."
  sleep 2
done
echo "✅ Simulator is Ready"

echo "--- 🧪 Testing"
rake mocks &
set +e
bundle exec fastlane test_without_building name:"$TEST_NAME" device:"$DEVICE"
TESTS_EXIT_STATUS=$?
set -e

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "UI Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd fastlane/test_output/ && zip -rq WooCommerce.xcresult.zip WooCommerce.xcresult && cd -

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "UI Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The UI Tests, which ran inside the '🧪 Testing' section above in the logs, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🧪 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "fastlane/test_output/WooCommerce.xml" --slack "build-and-ship"
else
    annotate_test_failures "fastlane/test_output/WooCommerce.xml"
fi

exit $TESTS_EXIT_STATUS
