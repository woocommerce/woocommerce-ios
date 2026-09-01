#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
set +e
bundle exec fastlane build_and_upload_prototype_build
BUILD_STATUS=$?
set -e

if [[ $BUILD_STATUS -ne 0 ]]; then
  GYM_LOG="${HOME}/Library/Logs/gym/WooCommerce-WooCommerce Alpha.log"
  if [[ -f "$GYM_LOG" ]]; then
    cp "$GYM_LOG" firebase-prototype-build-failed.log
    buildkite-agent artifact upload firebase-prototype-build-failed.log || true
    echo 'Full gym log uploaded as artifact `firebase-prototype-build-failed.log`.'
  else
    echo "Expected gym log was not found at: $GYM_LOG"
  fi
  exit $BUILD_STATUS
fi
