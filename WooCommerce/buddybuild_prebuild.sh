#!/usr/bin/env bash

echo "warning: Detected Prebuild Step"
mkdir -p ~/.mobile-secrets/iOS/WCiOS/
cp ${BUDDYBUILD_SECURE_FILES}/woo_app_credentials.json ~/.mobile-secrets/iOS/WCiOS/woo_app_credentials.json
echo "warning: Copied files over"

