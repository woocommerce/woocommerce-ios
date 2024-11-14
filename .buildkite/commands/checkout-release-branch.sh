#!/bin/bash -eu

RELEASE_VERSION="${1:?RELEASE_VERSION parameter missing}"

echo "--- :git: Checkout Release Branch"

# Buildkite, by default, checks out a specific commit. For many release actions, we need to be
# on a release branch instead.
BRANCH_NAME="release/${RELEASE_VERSION}"
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
