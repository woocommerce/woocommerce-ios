#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🧪 Testing"
set +e
# Without a device, fastlane picks `iPhone 17 Pro`, which on the `xcode-27.2` image exists only
# on the iOS 26.5 runtime. `iPhone 18 Pro` is on iOS 27.2.
bundle exec fastlane test_without_building name:UnitTests device:"iPhone 18 Pro"
TESTS_EXIT_STATUS=$?
set -e

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd fastlane/test_output/ && zip -rq WooCommerce.xcresult.zip WooCommerce.xcresult && cd -

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Unit Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The Unit Tests, which ran inside the '🧪 Testing' section above in the logs, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🧪 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "fastlane/test_output/report.junit" --slack "build-and-ship"
else
    annotate_test_failures "fastlane/test_output/report.junit"
fi

exit $TESTS_EXIT_STATUS
