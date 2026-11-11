#!/bin/bash -eu

# Trunk prototypes are explicitly requested; always produce the requested binary.
if [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]] && .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_prototype_build
