#!/bin/bash -eu

UI_TEST_PR_LABEL="${UI_TEST_PR_LABEL:-run ui tests}"

pr_has_label() {
  local pr_number="$1"
  local expected_label="$2"

  ruby -rjson -rnet/http -ruri -e '
    repo = ENV.fetch("GITHUB_REPO", "woocommerce/woocommerce-ios")
    pr_number = ARGV.fetch(0)
    expected_label = ARGV.fetch(1).downcase

    uri = URI("https://api.github.com/repos/#{repo}/issues/#{pr_number}/labels")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"

    token = ENV.fetch("GITHUB_TOKEN", "")
    request["Authorization"] = "Bearer #{token}" unless token.empty?

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    unless response.is_a?(Net::HTTPSuccess)
      warn "Could not fetch labels for PR ##{pr_number}: #{response.code} #{response.message}"
      exit 2
    end

    labels = JSON.parse(response.body).map { |label| label.fetch("name", "") }
    exit(labels.any? { |label| label.downcase == expected_label } ? 0 : 1)
  ' "$pr_number" "$expected_label"
}

# PR UI tests are opt-in, mirroring the `generate screenshots` GitHub Actions label gate.
# Add the `run ui tests` label before the CI run to execute these jobs on a PR.
if [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]; then
  if pr_has_label "$BUILDKITE_PULL_REQUEST" "$UI_TEST_PR_LABEL"; then
    echo "--- :label: Running UI tests because PR #$BUILDKITE_PULL_REQUEST has the '$UI_TEST_PR_LABEL' label"
  else
    label_status=$?
    if [[ "$label_status" -eq 2 ]]; then
      echo "--- :warning: Skipping — unable to verify PR labels for UI test opt-in"
    else
      echo "--- :fast_forward: Skipping — add the '$UI_TEST_PR_LABEL' label to run UI tests on this PR"
    fi
    exit 0
  fi
elif .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

TEST_NAME=$1
DEVICE=$2

echo "Running $TEST_NAME on $DEVICE"

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
"$(dirname "$SCRIPT_PATH")/shared-set-up.sh"

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
