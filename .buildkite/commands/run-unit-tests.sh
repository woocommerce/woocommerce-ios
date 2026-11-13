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
bundle exec fastlane test_without_building name:UnitTests 2>&1 | tee fastlane-unit-tests.log
TESTS_EXIT_STATUS=${PIPESTATUS[0]}
set -e

echo "+++ :mag: Validation: CI scan settings"
grep -E '^\[[0-9:]+\]: Found simulator|\| (device|deployment_target_version|app_name|disallow_xcodebuild_settings_lookup) ' fastlane-unit-tests.log || true
grep -Eq '\| disallow_xcodebuild_settings_lookup +\| true' fastlane-unit-tests.log || { echo 'FAIL: settings lookup not disabled on CI'; exit 1; }
grep -Eq '\| device +\| iPhone 17 Pro ' fastlane-unit-tests.log || { echo 'FAIL: CI did not default to iPhone 17 Pro'; exit 1; }
if grep -q 'showBuildSettings' fastlane-unit-tests.log; then echo 'FAIL: scan ran xcodebuild -showBuildSettings'; exit 1; fi
echo 'PASS: CI used iPhone 17 Pro without an xcodebuild settings lookup'

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
