#!/bin/bash -eu

set -o pipefail

#
# Runs SwiftLint on the whole workspace.
#
# This does not run in Continuous Integration.
#

# Abort if we are running in CI
# See https://circleci.com/docs/2.0/env-vars/#built-in-environment-variables
if [ "${CI-}" = true ] ; then
  echo "warning: skipping SwiftLint build phase because running on CI."
  exit 0
fi

# Get the directory of this file.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Temporarily move to the root directory so that SwiftLint can correctly
# find the paths returned from the `git` commands below.
pushd "$DIR/../../" > /dev/null || exit 1

# Paths are now relative to the root directory
SWIFTLINT_BIN="./Pods/SwiftLint/swiftlint"

if ! which "$SWIFTLINT_BIN" >/dev/null; then
  echo "error: SwiftLint is not installed. Install by running \`rake dependencies\`."
  exit 1
fi

# DRY linting call in function so that we can be robust against paths with spaces
lint_files() {
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      "$SWIFTLINT_BIN" lint --quiet "$file"
    fi
  done
}

# Run SwiftLint on the modified files.
#
# The `|| true` at the end is to stop `grep` from returning a non-zero exit if there
# are no matches. Xcode's build will fail if we don't do this.
#
MODIFIED_FILES=$(git diff --name-only --diff-filter=d HEAD | grep -G "\.swift$" || true)
echo "$MODIFIED_FILES" | lint_files
MODIFIED_FILES_LINT_RESULT=$?

# Run SwiftLint on the added files
ADDED_FILES=$(git ls-files --others --exclude-standard | grep -G "\.swift$" || true)
echo "$ADDED_FILES" | lint_files
ADDED_FILES_LINT_RESULT=$?

# Restore the previous directory
popd > /dev/null || exit 1

# Exit with non-zero if SwiftLint found a serious violation in the linted files.
#
# This stops Xcode from complaining about "...did not return a nonzero exit code...".
#
if [ $MODIFIED_FILES_LINT_RESULT -ne 0 ] || [ $ADDED_FILES_LINT_RESULT -ne 0 ] ; then
  exit 1
fi
