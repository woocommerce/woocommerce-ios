#!/usr/bin/env bash

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

## Validate Secrets!
##
if [ ! -f $SECRETS_PATH ]; then

    echo ">> Using Templated Secrets"

    ## Generate the Derived Folder. If needed
    ##
    mkdir -p ${DERIVED_PATH}

    ## Create a credentials file from the template (if needed)
    ## then copy it into place for the build.
    ##
    if [ ! -f $CREDS_OUTPUT_PATH ]; then
        echo ">> Creating Credentials File from Template: ${CREDS_FILE_PATH}"
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
        echo ">> Creating Bash Secrets File from Template: ${BASH_FILE_PATH}"
        cp ${BASH_INPUT_PATH} ${BASH_OUTPUT_PATH}
    fi

else

    echo ">> Loading Secrets ${SECRETS_PATH}"

    ## Generate the Derived Folder. If needed
    ##
    mkdir -p ${DERIVED_PATH}

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
