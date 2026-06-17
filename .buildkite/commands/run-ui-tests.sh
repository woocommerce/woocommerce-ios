#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

UI_TEST_CHANGE_PATTERNS=(
  'WooCommerce/WooCommerceUITests/**'
  'Modules/Sources/UITestsFoundation/**'
  'Modules/Sources/APIMocks/**'
  'API-Mocks/**'
  '.buildkite/commands/run-ui-tests.sh'
  '.buildkite/pipeline.yml'
)

# On PR builds, run UI tests only when the PR changes the UI test suite or its test-only support files.
# Non-PR trunk/release builds remain eligible through pipeline.yml and are not filtered by this PR-only check.
if [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]; then
  if ! pr_changed_files --any-match "${UI_TEST_CHANGE_PATTERNS[@]}"; then
    echo "--- :fast_forward: Skipping — no UI test changes in this PR"
    exit 0
  fi
fi

TEST_NAME=$1
DEVICE=$2

echo "Running $TEST_NAME on $DEVICE"

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
    annotate_test_failures "fastlane/test_output/report.junit" --slack "build-and-ship"
else
    annotate_test_failures "fastlane/test_output/report.junit"
fi

exit $TESTS_EXIT_STATUS
