#!/bin/bash -u

echo "--- :swift: Running SwiftLint"

# Run SwiftLint only on the modified files, similarly to what is done on Scripts/build-phases/swiftlint.sh
MODIFIED_SWIFT_FILES=$(git diff --name-only --diff-filter=d HEAD -- '*.swift' \
                     $(git ls-files --others --exclude-standard -- '*.swift'))

set +e
SWIFTLINT_OUTPUT=$(echo "$MODIFIED_SWIFT_FILES" | xargs swiftlint lint --quiet "$@" --reporter relative-path)
SWIFTLINT_EXIT_STATUS=$?
set -e

WARNINGS=$(echo -e "$SWIFTLINT_OUTPUT" | awk -F': ' '/: warning:/ {printf "- `%s`: %s\n", $1, $4}')
ERRORS=$(echo -e "$SWIFTLINT_OUTPUT" | awk -F': ' '/: error:/ {printf "- `%s`: %s\n", $1, $4}')

if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS"
  printf "**SwiftLint Warnings**\n%b" "$WARNINGS" | buildkite-agent annotate --style 'warning'
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS"
  printf "**SwiftLint Errors**\n%b" "$ERRORS" | buildkite-agent annotate --style 'error'
fi

exit $SWIFTLINT_EXIT_STATUS
