#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_prototype_build
