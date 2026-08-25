#!/usr/bin/env bash

set -euo pipefail

# Interpolate ApiCredentials.tpl against the decrypted secrets JSON.
# Runs outside xcodebuild so a missing key is visible in the job log
# (xcbeautify swallows Generate Credentials script-phase output).

SECRETS_PATH="${HOME}/.configure/woocommerce-ios/secrets/woo_app_credentials.json"
TPL_PATH="WooCommerce/Credentials/ApiCredentials.tpl"
SCRIPT_PATH="WooCommerce/Credentials/replace_secrets.rb"

if [[ ! -f "${SECRETS_PATH}" ]]; then
  echo "error: Secrets file not found at ${SECRETS_PATH}. Run configure_apply first." >&2
  exit 1
fi

if [[ ! -f "${TPL_PATH}" || ! -f "${SCRIPT_PATH}" ]]; then
  echo "error: Expected ${TPL_PATH} and ${SCRIPT_PATH} to exist." >&2
  exit 1
fi

ruby "${SCRIPT_PATH}" -i "${TPL_PATH}" -s "${SECRETS_PATH}" >/dev/null
