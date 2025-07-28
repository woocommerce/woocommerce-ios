#!/bin/bash -eu

#
# Runs SwiftLint on the whole workspace.
#
# This does not run in Continuous Integration.
#

# Do not run in CI environments.
# Our CI has its own static linter.
if [ -n "${CI+x}" ]; then
  echo 'CI environment detected. Skipping SwiftLint build phase in favor of dedicated CI process.'
  exit 0
fi

rake lint
