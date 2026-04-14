#!/usr/bin/env bash

set -euo pipefail

if [[ $ACTION == 'indexbuild' ]]; then
  echo "ℹ️: Skipping code generation in 'indexbuild' build. See https://github.com/mac-cain13/R.swift/issues/719#issuecomment-937733804 for more info."
  exit 0
fi

SCRIPT_PATH=${SOURCE_ROOT}/Credentials/replace_secrets.rb
CREDS_INPUT_PATH=${SOURCE_ROOT}/Credentials/ApiCredentials.tpl
CREDS_TEMPLATE_PATH=${SOURCE_ROOT}/Credentials/Templates/ApiCredentials-Template.swift
SECRETS_PATH="${HOME}/.configure/woocommerce-ios/secrets/woo_app_credentials.json"

## Collect output paths from the per-target build phase's `outputPaths`.
## Xcode exposes them as SCRIPT_OUTPUT_FILE_N (with SCRIPT_OUTPUT_FILE_COUNT).
##
if [[ -z "${SCRIPT_OUTPUT_FILE_COUNT:-}" || "${SCRIPT_OUTPUT_FILE_COUNT}" -lt 1 ]]; then
    echo "error: generate-credentials.sh expects at least one output file declared via the build phase's outputPaths." >&2
    exit 1
fi

OUTPUT_PATHS=()
for (( i=0; i<SCRIPT_OUTPUT_FILE_COUNT; i++ )); do
    var="SCRIPT_OUTPUT_FILE_${i}"
    OUTPUT_PATHS+=("${!var}")
    mkdir -p "$(dirname "${!var}")"
done

## Validate Secrets!
##
if [ ! -f "$SECRETS_PATH" ]; then

    echo "warning: Could not find secrets at $SECRETS_PATH. This is likely due to the secrets folder being missing. Falling back to templated secrets. If you are an internal contributor, run \`bundle exec fastlane run configure_apply\` to update your secrets"

    echo ">> Using Templated Secrets"

    for OUTPUT_PATH in "${OUTPUT_PATHS[@]}"; do
        if [ ! -f "${OUTPUT_PATH}" ]; then
            echo ">> Creating Credentials File from Template: ${CREDS_TEMPLATE_PATH} -> ${OUTPUT_PATH}"
            cp "${CREDS_TEMPLATE_PATH}" "${OUTPUT_PATH}"
        fi
    done

else

    echo ">> Loading Secrets ${SECRETS_PATH}"

    if which rbenv; then
      # Fix an issue where, depending on the shell you are using on your machine and your rbenv setup,
      #   running `ruby` in a bash script from Xcode script build phase might not use the right ruby
      #   (and thus not find the appropriate gems installed by bundle & Gemfile.lock and crash).
      # So if rbenv is installed, make sure the shims for `ruby` are too in the context of this bash script,
      #   so that it uses the right ruby version defined in `.ruby-version` instead of risking to use the system one.
      eval "$(rbenv init -)"
      rbenv rehash
    fi

    for OUTPUT_PATH in "${OUTPUT_PATHS[@]}"; do
        echo ">> Generating Credentials ${OUTPUT_PATH}"
        ruby "${SCRIPT_PATH}" -i "${CREDS_INPUT_PATH}" -s "${SECRETS_PATH}" > "${OUTPUT_PATH}"
    done

fi
