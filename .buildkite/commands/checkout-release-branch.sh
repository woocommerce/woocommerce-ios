#!/bin/bash -eu

# Note: `BUILDKITE_RELEASE_VERSION` is the legacy environment variable passed to Buildkite by ReleaseV2.
# It used the `BUILDKITE_` prefix so it was not filtered out when passed to the MacOS VMs, due to how `hostmgr` works.
# This is considered legacy: we should eventually remove all use of custom `BUILDKITE_` variables, and instead
# resolve the value of those sooner (i.e. in the YML pipeline) then pass it as parameter to the `.sh` calls instead.

# Use the provided argument if there's one, otherwise fall back to the legacy BUILDKITE_RELEASE_VERSION
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
