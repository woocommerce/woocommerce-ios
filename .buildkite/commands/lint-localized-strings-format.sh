#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type localization; then
  exit 0
fi

lint_localized_strings_format
