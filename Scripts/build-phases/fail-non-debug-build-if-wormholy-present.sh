#!/bin/bash -eu

# Checks if the SwiftPM setup includes Wormholy during a build that is not Debug.
#
# If that's the case, it fails the build, because we don't want the library in non Debug builds.
#
# See counterpart method remove_wormholy_dependency_from_package_swift in fastlane/Fastfile.

MODULES_PATH="${SRCROOT}/../Modules"
PACKAGE_PATH="${MODULES_PATH}/Package.swift"
# Note: when/if we'll remove the workspace, this will change to ${MODULES_PATH}/Package.resolved
PACKAGE_RESOLVED_PATH="${SRCROOT}/../WooCommerce.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "info: Running in Debug build configuration. Skipping Wormholy check."
  exit 0
else
  echo "info: Running with a build configuration that is not Debug (${CONFIGURATION}). Checking Wormholy is not part of the SwiftPM setup..."
fi

EXPLANATION="You are likely running a distribution build from Xcode, which cannot strip Wormholy. Please build for distribution using Fastlane (\`bundle exec fastlane build_for_app_store_connect\` or \`bundle exec fastlane build_for_prototype_build\`)."

if grep --quiet "Wormholy" "${PACKAGE_PATH}"; then
  echo "error: Wormholy reference found in Package.swift. $EXPLANATION"
  exit 1
fi

# This is not necessary from the build point of view, because Package.swift is the source of truth.
# But checking it ensures that the packages were resolved before starting the build.

if grep --quiet "Wormholy" "${PACKAGE_RESOLVED_PATH}"; then
  echo "error: Wormholy reference found in Package.resolved. $EXPLANATION"
  exit 1
fi

echo "info: Wormholy not found in SwiftPM setup. Proceeding with the build..."
