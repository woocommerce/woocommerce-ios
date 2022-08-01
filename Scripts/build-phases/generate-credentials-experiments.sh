#!/usr/bin/env bash -euo pipefail

if [[ $ACTION == 'indexbuild' ]]; then
  echo "ℹ️: Skipping code generation in 'indexbuild' build. See https://github.com/mac-cain13/R.swift/issues/719#issuecomment-937733804 for more info."
  exit 0
fi

DERIVED_PATH=${SOURCE_ROOT}/Experiments/DerivedSources
GOOGLE_SERVICE_INFO_PLIST_OUTPUT_PATH=${DERIVED_PATH}/GoogleService-Info.plist
GOOGLE_SERVICE_INFO_PLIST_PATH="${HOME}/.configure/woocommerce-ios/secrets/GoogleService-Info.plist"

GOOGLE_SERVICE_INFO_PLIST_TEMPLATE_PATH=${SOURCE_ROOT}/Experiments/GoogleService-Info-template.plist

## Validate Secrets!
##
if [ ! -f $GOOGLE_SERVICE_INFO_PLIST_PATH ]; then
    echo "warning: Could not find secrets at $GOOGLE_SERVICE_INFO_PLIST_PATH. This is likely due to the secrets folder being missing. Falling back to templated secrets. If you are an internal contributor, run \`bundle exec fastlane run configure_apply\` to update your secrets"

    if [ ! -f $GOOGLE_SERVICE_INFO_PLIST_OUTPUT_PATH ]; then
        echo ">> Creating Google Service Info File from Template: ${GOOGLE_SERVICE_INFO_PLIST_TEMPLATE_PATH}"
        cp ${GOOGLE_SERVICE_INFO_PLIST_TEMPLATE_PATH} ${GOOGLE_SERVICE_INFO_PLIST_OUTPUT_PATH}
    fi
else
    echo ">> Loading Google service info ${GOOGLE_SERVICE_INFO_PLIST_PATH}"

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

    ## Create a bash secrets file from the template (if needed)
    ## then copy it into place for the build.
    ##
    echo ">> Generating Credentials: ${GOOGLE_SERVICE_INFO_PLIST_OUTPUT_PATH}"
    cp ${GOOGLE_SERVICE_INFO_PLIST_PATH} ${GOOGLE_SERVICE_INFO_PLIST_OUTPUT_PATH}

fi
