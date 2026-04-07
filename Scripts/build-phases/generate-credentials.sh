#!/usr/bin/env bash -euo pipefail

if [[ $ACTION == 'indexbuild' ]]; then
  echo "ℹ️: Skipping code generation in 'indexbuild' build. See https://github.com/mac-cain13/R.swift/issues/719#issuecomment-937733804 for more info."
  exit 0
fi

DERIVED_PATH=${SOURCE_ROOT}/DerivedSources
CLASSES_DERIVED_PATH=${SOURCE_ROOT}/DerivedSources/WooCommerce
WATCH_DERIVED_PATH=${SOURCE_ROOT}/DerivedSources/WatchApp
SCRIPT_PATH=${SOURCE_ROOT}/Credentials/replace_secrets.rb

CREDS_INPUT_PATH=${SOURCE_ROOT}/Credentials/ApiCredentials.tpl
CREDS_TEMPLATE_PATH=${SOURCE_ROOT}/Credentials/Templates/ApiCredentials-Template.swift

BASH_INPUT_PATH=${SOURCE_ROOT}/Credentials/bash_secrets.tpl
BASH_OUTPUT_PATH=${DERIVED_PATH}/bash_secrets

SECRETS_PATH="${HOME}/.configure/woocommerce-ios/secrets/woo_app_credentials.json"

## Validate Secrets!
##
if [ ! -f $SECRETS_PATH ]; then

    echo "warning: Could not find secrets at $SECRETS_PATH. This is likely due to the secrets folder being missing. Falling back to templated secrets. If you are an internal contributor, run \`bundle exec fastlane run configure_apply\` to update your secrets"

    echo ">> Using Templated Secrets"

    ## Generate the Derived folders, if needed
    ##
    mkdir -p ${DERIVED_PATH}
    mkdir -p ${CLASSES_DERIVED_PATH}
    mkdir -p ${WATCH_DERIVED_PATH}

    ## Create credentials files from the template (if needed)
    ##
    for TARGET_PATH in ${CLASSES_DERIVED_PATH} ${WATCH_DERIVED_PATH}; do
        if [ ! -f "${TARGET_PATH}/ApiCredentials.swift" ]; then
            echo ">> Creating Credentials File from Template: ${CREDS_TEMPLATE_PATH} -> ${TARGET_PATH}"
            cp ${CREDS_TEMPLATE_PATH} "${TARGET_PATH}/ApiCredentials.swift"
        fi
    done

    ## Create a bash secrets file from the template (if needed)
    ##
    if [ ! -f $BASH_OUTPUT_PATH ]; then
        echo ">> Creating Bash Secrets File from Template: ${BASH_INPUT_PATH}"
        cp ${BASH_INPUT_PATH} ${BASH_OUTPUT_PATH}
    fi

else

    echo ">> Loading Secrets ${SECRETS_PATH}"

    ## Generate the Derived folders, if needed
    ##
    mkdir -p ${DERIVED_PATH}
    mkdir -p ${CLASSES_DERIVED_PATH}
    mkdir -p ${WATCH_DERIVED_PATH}

    if which rbenv; then
      # Fix an issue where, depending on the shell you are using on your machine and your rbenv setup,
      #   running `ruby` in a bash script from Xcode script build phase might not use the right ruby
      #   (and thus not find the appropriate gems installed by bundle & Gemfile.lock and crash).
      # So if rbenv is installed, make sure the shims for `ruby` are too in the context of this bash script,
      #   so that it uses the right ruby version defined in `.ruby-version` instead of risking to use the system one.
      eval "$(rbenv init -)"
      rbenv rehash
    fi

    ## Generate ApiCredentials.swift into per-target DerivedSources folders
    ##
    for TARGET_PATH in ${CLASSES_DERIVED_PATH} ${WATCH_DERIVED_PATH}; do
        echo ">> Generating Credentials ${TARGET_PATH}/ApiCredentials.swift"
        ruby ${SCRIPT_PATH} -i ${CREDS_INPUT_PATH} -s ${SECRETS_PATH} > "${TARGET_PATH}/ApiCredentials.swift"
    done

    ## Generate bash_secrets
    ##
    echo ">> Generating Credentials ${BASH_OUTPUT_PATH}"
    ruby ${SCRIPT_PATH} -i ${BASH_INPUT_PATH} -s ${SECRETS_PATH} > ${BASH_OUTPUT_PATH}

fi
