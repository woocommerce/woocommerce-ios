#!/bin/bash -eu

if [ "${CONFIGURATION}" != "Release" ]; then
  echo "info: Skipping Wormholy removal – not a Release build."
  exit 0
fi

BUILT_PRODUCTS_DIR=${BUILT_PRODUCTS_DIR:-"$TARGET_BUILD_DIR"}

# Crude way to remove all the Wormholy files from the build.
rm -rf "$BUILT_PRODUCTS_DIR/Wormholy*"
