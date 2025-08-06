#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

### Prepare

echo '--- 📦 Downloading Build Artifacts'
buildkite-agent artifact download build-products.tar .
tar -xf build-products.tar

### Run the Tests

PERIPHERY_OUTPUT_FILE="periphery-errors.txt"

echo '+++ :zombie: Detecting unused code'
set +e
# This is the script in the root.
./Scripts/Periphery/setup-and-run-periphery.sh \
  --strict --quiet --skip-build --index-store-path 'DerivedData/Index.noindex/DataStore/' \
  --write-results "$PERIPHERY_OUTPUT_FILE"
TESTS_EXIT_STATUS=$?
set -e

# Handle the result of the periphery scan
if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  echo '😱 Unused code detected!'
  echo ''
  echo '💡 You can run Periphery locally by calling `setup-and-run-periphery.sh` from `./Scripts/Periphery/` in the repo.'
  echo ''
  echo 'If you think there is a false positive violation, please check the known issues of Periphery at https://github.com/peripheryapp/periphery/issues.'
  echo 'If you think a violation is valid but it should be surpressed for any reason, please apply the `// periphery: ignore - {your-reason-here}` comment.'
  echo ''
  # Add the periphery errors as a Buildkite annotation
  (echo "### Periphery found unused code"; echo ''; echo '```'; cat "$PERIPHERY_OUTPUT_FILE"; echo ''; echo '```') \
    | buildkite-agent annotate --context periphery --style error
else
  echo '😊 No unused code found.'
  buildkite-agent annotate --context periphery --style success 'No unused code found by Periphery :tada:'
fi

echo '--- 🚦 Report Exit code'
exit $TESTS_EXIT_STATUS
