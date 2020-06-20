#!/bin/bash

#
# Runs SwiftLint on the whole workspace
#

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Temporarily move to the root directory so that SwiftLint can correctly
# determine the paths declared under the .swiftlint.yml `include` property.
pushd $DIR/../../ > /dev/null

# Paths relative to the root directory
SWIFTLINT="./vendor/swiftlint/bin/swiftlint"
CONFIG_FILE=".swiftlint.yml"

if ! which $SWIFTLINT >/dev/null; then
  echo "error: SwiftLint is not installed. Install by running `rake dependencies`."
  exit 1
fi

$SWIFTLINT --config $CONFIG_FILE --quiet

# Restore the previous directory
popd > /dev/null