#!/bin/bash -eu

# Note: BUILDKITE_RELEASE_VERSION is passed as an environment variable from fastlane to Buildkite
# It must use the `BUILDKITE_` prefix to be passed to the agent due to how `hostmgr` works.
# This is considered legacy and we should eventually remove all custom BUILDKITE_ variables.

# Use the provided RELEASE_VERSION if set, otherwise fall back to the legacy BUILDKITE_RELEASE_VERSION
RELEASE_VERSION=${1:-$BUILDKITE_RELEASE_VERSION}

if [[ -z "${RELEASE_VERSION}" ]]; then
    echo "RELEASE_VERSION is not set and BUILDKITE_RELEASE_VERSION is not available."
    exit 1
fi

# Buildkite, by default, checks out a specific commit. For many release actions, we need to be
# on a release branch instead.
BRANCH_NAME="release/${RELEASE_VERSION}"
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
