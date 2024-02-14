#!/bin/bash -u

echo "--- :swift: Running SwiftLint"

# Run SwiftLint only on the modified files, similarly to what is done on Scripts/build-phases/swiftlint.sh

PULL_REQUEST_REPO="${BUILDKITE_PULL_REQUEST_REPO%.git}"
PULL_REQUEST_DIFF_URL="$PULL_REQUEST_REPO/pull/$BUILDKITE_PULL_REQUEST.diff"

# fetch the diff file using Swift -- the SwiftLint image doesn't have curl or wget
DIFF_FILE=$(swift - <<'EOF'
  import Foundation
  if let data = try? Data(contentsOf: URL(string: "$PULL_REQUEST_DIFF_URL")!), let diffFile = String(data: data, encoding: .utf8) {
      print(diffFile)
  } else {
      fatalError("Failed to fetch or decode diff file")
  }
EOF
)

MODIFIED_SWIFT_FILES=$(echo "$DIFF_FILE" | grep '^diff --git' | sed 's/^diff --git a\///' | cut -d' ' -f1)

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
