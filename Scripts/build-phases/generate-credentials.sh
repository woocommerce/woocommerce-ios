#!/usr/bin/env bash -euo pipefail

if [[ $ACTION == 'indexbuild' ]]; then
  echo "ℹ️: Skipping code generation in 'indexbuild' build. See https://github.com/mac-cain13/R.swift/issues/719#issuecomment-937733804 for more info."
  exit 0
fi

DERIVED_PATH=${SOURCE_ROOT}/DerivedSources
SCRIPT_PATH=${SOURCE_ROOT}/Credentials/replace_secrets.rb

CREDS_INPUT_PATH=${SOURCE_ROOT}/Credentials/ApiCredentials.tpl
CREDS_OUTPUT_PATH=${DERIVED_PATH}/ApiCredentials.swift

CREDS_TEMPLATE_PATH=${SOURCE_ROOT}/Credentials/Templates/ApiCredentials-Template.swift

PLIST_INPUT_PATH=${SOURCE_ROOT}/Credentials/InfoPlist.tpl
PLIST_OUTPUT_PATH=${DERIVED_PATH}/InfoPlist.h

PLIST_TEMPLATE_PATH=${SOURCE_ROOT}/Credentials/Templates/InfoPlist-Template.h

BASH_INPUT_PATH=${SOURCE_ROOT}/Credentials/bash_secrets.tpl
BASH_OUTPUT_PATH=${DERIVED_PATH}/bash_secrets

SECRETS_PATH="${HOME}/.configure/woocommerce-ios/secrets/woo_app_credentials.json"

## Validate Secrets!
##
if [ ! -f $SECRETS_PATH ]; then

    echo "warning: Could not find secrets at $SECRETS_PATH. This is likely due to the secrets folder being missing. Falling back to templated secrets. If you are an internal contributor, run \`bundle exec fastlane run configure_apply\` to update your secrets"

    echo ">> Using Templated Secrets"

    ## Generate the Derived Folder. If needed
    ##
    mkdir -p ${DERIVED_PATH}

    ## Create a credentials file from the template (if needed)
    ## then copy it into place for the build.
    ##
    if [ ! -f $CREDS_OUTPUT_PATH ]; then
        echo ">> Creating Credentials File from Template: ${CREDS_TEMPLATE_PATH}"
        cp ${CREDS_TEMPLATE_PATH} ${CREDS_OUTPUT_PATH}
    fi

    ## Create a plist file from the template (if needed)
    ## then copy it into place for the build.
    ##
    if [ ! -f $PLIST_OUTPUT_PATH ]; then
        echo ">> Creating plist File from Template: ${PLIST_OUTPUT_PATH}"
        cp ${PLIST_TEMPLATE_PATH} ${PLIST_OUTPUT_PATH}
    fi

    ## Create a bash secrets file from the template (if needed)
    ## then copy it into place for the build.
    ##
    if [ ! -f $BASH_OUTPUT_PATH ]; then
        echo ">> Creating Bash Secrets File from Template: ${BASH_INPUT_PATH}"
        cp ${BASH_INPUT_PATH} ${BASH_OUTPUT_PATH}
    fi

else

    echo ">> Loading Secrets ${SECRETS_PATH}"

    ## Generate the Derived Folder. If needed
    ##
    mkdir -p ${DERIVED_PATH}

    if which rbenv; then
      # Fix an issue where, depending on the shell you are using on your machine and your rbenv setup,
      #   running `ruby` in a bash script from Xcode script build phase might not use the right ruby
      #   (and thus not find the appropriate gems installed by bundle & Gemfile.lock and crash).
      # So if rbenv is installed, make sure the shims for `ruby` are too in the context of this bash script,
      #   so that it uses the right ruby version defined in `.ruby-version` instead of risking to use the system one.
      eval "$(rbenv init -)"
      rbenv rehash
    fi

    ## Generate ApiCredentials.swift
    ##
    echo ">> Generating Credentials ${CREDS_OUTPUT_PATH}"
    ruby ${SCRIPT_PATH} -i ${CREDS_INPUT_PATH} -s ${SECRETS_PATH} > ${CREDS_OUTPUT_PATH}

    ## Generate InfoPlist.h
    ##
    echo ">> Generating Credentials ${PLIST_OUTPUT_PATH}"
    ruby ${SCRIPT_PATH} -i ${PLIST_INPUT_PATH} -s ${SECRETS_PATH} > ${PLIST_OUTPUT_PATH}

    ## Generate bash_secrets
    ##
    echo ">> Generating Credentials ${BASH_OUTPUT_PATH}"
    ruby ${SCRIPT_PATH} -i ${BASH_INPUT_PATH} -s ${SECRETS_PATH} > ${BASH_OUTPUT_PATH}

fi
