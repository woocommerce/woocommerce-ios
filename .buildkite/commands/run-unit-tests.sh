#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- 🧪 Testing"
set +e
bundle exec fastlane test_without_building name:UnitTests
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

# Temporary read-only host check after verification; never replace the test exit status.
echo "--- 🔬 Inspecting failed process launches"
(
  PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/woomob-4430-launch.XXXXXX")" || exit 0
  trap 'rm -rf "$PROBE_DIR"' EXIT
  sw_vers
  plutil -extract CFBundleVersion raw /System/Library/Frameworks/Foundation.framework/Resources/Info.plist
  SIMCTL_BINARY=/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/Resources/bin/simctl
  xcrun dwarfdump --uuid "$SIMCTL_BINARY"
  if [[ -e /usr/bin/darwinup ]]; then
    echo "darwinup_present=yes"
    MISSING_EXECUTABLE="$PROBE_DIR/missing-executable"
  else
    echo "darwinup_present=no"
    MISSING_EXECUTABLE=/usr/bin/darwinup
  fi
  xcrun llvm-objdump --macho --arch=arm64e -d --section=__TEXT,__text --section=__TEXT,__objc_stubs "$SIMCTL_BINARY" |
    LC_ALL=C awk '/^10000d8a8:/,/^10000db90:/ { print }
         /Objc selector ref: (launchAndReturnError:|setLaunchPath:|waitUntilExit)$/ { print previous; print }
         { previous = $0 }'
  xcrun clang -fobjc-arc -Wno-deprecated-declarations \
    .buildkite/commands/probe-failed-process-launch.m -framework Foundation -o "$PROBE_DIR/probe" || exit 0
  for PROBE_SCENARIO in valid-background missing-main missing-background missing-checked; do
    PROBE_EXECUTABLE="$MISSING_EXECUTABLE"
    PROBE_THREAD=background
    PROBE_POLICY=unchecked
    case "$PROBE_SCENARIO" in
      valid-background) PROBE_EXECUTABLE=/usr/bin/true ;;
      missing-main) PROBE_THREAD=main ;;
      missing-checked) PROBE_POLICY=checked ;;
    esac
    echo "probe_scenario=$PROBE_SCENARIO"
    if "$PROBE_DIR/probe" "$PROBE_EXECUTABLE" "$PROBE_POLICY" "$PROBE_THREAD" null "$PROBE_DIR/output.log"; then
      echo "probe_exit=0"
    else
      echo "probe_exit=$?"
    fi
  done
) || true

exit $TESTS_EXIT_STATUS
