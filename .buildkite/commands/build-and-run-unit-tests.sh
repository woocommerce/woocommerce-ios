#!/bin/bash -eu

# Runs the unit tests in the job that builds them, so they reuse this agent's checkout, Swift packages and
# build products instead of setting all of them up again on another agent.
#
# The steps that only need the build output are uploaded as soon as it is available, so they don't wait
# for the unit tests.

COMMANDS_DIR="$(dirname "${BASH_SOURCE[0]}")"

upload_steps_once() {
  local pipeline_file=$1
  local meta_data_key
  meta_data_key="uploaded-$(basename "$pipeline_file" .yml)"

  # A retried job must not add the same steps to the build again.
  if buildkite-agent meta-data exists "$meta_data_key"; then
    return
  fi

  (
    # Provides the variables interpolated in the uploaded pipeline (e.g. $CI_TOOLKIT, $IMAGE_ID).
    source .buildkite/shared-pipeline-vars
    buildkite-agent pipeline upload "$pipeline_file"
  )
  buildkite-agent meta-data set "$meta_data_key" true
}

# The warning comparison also runs when the build fails, to report that the comparison is unavailable.
trap 'upload_steps_once .buildkite/build-warning-count.yml' EXIT

"$COMMANDS_DIR/build-for-testing.sh"

echo "--- :pipeline: Uploading the steps that need the build output"
upload_steps_once .buildkite/build-warning-count.yml
upload_steps_once .buildkite/ui-tests.yml

"$COMMANDS_DIR/run-unit-tests.sh"
