#!/usr/bin/env bash

echo "warning: Detected Prebuild Step"
cp ${BUDDYBUILD_SECURE_FILES}/woo_app_credentials.json ~/.woo_app_credentials.json
echo "warning: Copied files over"

