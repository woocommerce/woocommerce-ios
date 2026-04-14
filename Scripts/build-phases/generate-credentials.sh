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

## Collect output paths.
##
## Xcode populates SCRIPT_OUTPUT_FILE_N (and SCRIPT_OUTPUT_FILE_COUNT) from the
## build phase's `outputPaths`. When this script is invoked from a per-target
## build phase that declares its output in `$(DERIVED_FILE_DIR)`, we use those
## paths verbatim and write one file per invocation.
##
## When invoked from the legacy `GenerateCredentials` aggregate target — whose
## outputs are declared via an xcfilelist, which Xcode does *not* expand into
## SCRIPT_OUTPUT_FILE_N — we fall back to the per-target folders inside the
## repo's `DerivedSources/` tree.
##
OUTPUT_PATHS=()
if [[ -n "${SCRIPT_OUTPUT_FILE_COUNT:-}" && "${SCRIPT_OUTPUT_FILE_COUNT}" -gt 0 ]]; then
    for (( i=0; i<SCRIPT_OUTPUT_FILE_COUNT; i++ )); do
        var="SCRIPT_OUTPUT_FILE_${i}"
        OUTPUT_PATHS+=("${!var}")
    done
else
    OUTPUT_PATHS+=("${SOURCE_ROOT}/DerivedSources/WooCommerce/ApiCredentials.swift")
    OUTPUT_PATHS+=("${SOURCE_ROOT}/DerivedSources/WatchApp/ApiCredentials.swift")
fi

## Ensure each target's parent folder exists.
##
for OUTPUT_PATH in "${OUTPUT_PATHS[@]}"; do
    mkdir -p "$(dirname "${OUTPUT_PATH}")"
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
