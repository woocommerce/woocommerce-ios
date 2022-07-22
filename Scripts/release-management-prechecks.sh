#!/bin/bash

# ---------------------------------------------------------------------------------
# 0a. Configuration
# ---------------------------------------------------------------------------------

PROJECT_ROOT="."
PROJECT_ENV_FILE="$HOME/.wcios-env.default"

P_ENV_GITHUB_TOKEN="GITHUB_TOKEN"
P_ENV_SENTRY_AUTH_TOKEN="SENTRY_AUTH_TOKEN"
P_ENV_SENTRY_ORG_SLUG="SENTRY_ORG_SLUG"
P_ENV_SENTRY_PROJECT_SLUG="SENTRY_PROJECT_SLUG"
P_ENV_BUILDKITE_TOKEN="BUILDKITE_TOKEN"

# TODO: Can we drop these values from the 'PROJECT_ENV_FILE' and add it to the repo?
# We can simplify and improve this script if we can do that.
P_ENV_SENTRY_ORG_SLUG_VALUE="a8c"
P_ENV_SENTRY_PROJECT_SLUG_VALUE="woocommerce-ios"

# ---------------------------------------------------------------------------------
# 0b. Warning & Error Messages
# ---------------------------------------------------------------------------------
echoerr() { printf "\e[31;1m%s\e[0m\n" "$*" >&2; }
error_incorrect_ruby_version() {
    echoerr \
"Your local ruby version does not match the required ruby version.
Please make sure \`ruby --version\` returns the same version as the version in \`.ruby-version\` file.
We suggest using rbenv for managing your Ruby environment: https://github.com/rbenv/rbenv"
}

error_project_env_file_missing() {
    echoerr "$PROJECT_ENV_FILE is missing!"
}
error_project_env_field_missing() {
    echoerr "'$1' is missing or incorrect in $PROJECT_ENV_FILE!"
}
warning_project_env_file_contents() {
    echo \
"
Please make sure you have the following information in '$PROJECT_ENV_FILE':

> $P_ENV_GITHUB_TOKEN={$P_ENV_GITHUB_TOKEN}
>
> $P_ENV_SENTRY_AUTH_TOKEN={$P_ENV_SENTRY_AUTH_TOKEN}
> $P_ENV_SENTRY_ORG_SLUG=$P_ENV_SENTRY_ORG_SLUG_VALUE
> $P_ENV_SENTRY_PROJECT_SLUG=$P_ENV_SENTRY_PROJECT_SLUG_VALUE
>
> $P_ENV_BUILDKITE_TOKEN={$P_ENV_BUILDKITE_TOKEN}

Here is how to retrieve these values:

$P_ENV_GITHUB_TOKEN: https://github.com/settings/tokens (requires 'repo')
$P_ENV_SENTRY_AUTH_TOKEN: https://sentry.io/settings/account/api/auth-tokens/ (requires 'event:read, member:read, org:read, project:read, project:releases, team:read, event:admin')
$P_ENV_BUILDKITE_TOKEN: https://buildkite.com/user/api-access-tokens (requires: 'Organizations: Automattic' & 'REST Scopes: read_builds, write_builds')
"
}

# ---------------------------------------------------------------------------------
# 0c. Helpers
# ---------------------------------------------------------------------------------

HAS_WARNINGS=false
LOG_SEPERATOR="
------------------------------------------------------------------------
"

# ---------------------------------------------------------------------------------
# 1. Checking Ruby Version
# ---------------------------------------------------------------------------------

PROJECT_RUBY_VERSION=$(cat $PROJECT_ROOT/.ruby-version)
LOCAL_RUBY_VERSION=$(ruby -e 'puts RUBY_VERSION')

if [ "$LOCAL_RUBY_VERSION" != "$PROJECT_RUBY_VERSION" ]; then
    echo "Local Ruby Version: $LOCAL_RUBY_VERSION"
    echo "Project Ruby Version: $PROJECT_RUBY_VERSION"
    error_incorrect_ruby_version
    echo "$LOG_SEPERATOR"

    HAS_WARNINGS=true
fi

# ---------------------------------------------------------------------------------
# 2. Checking Environment File
# ---------------------------------------------------------------------------------

HAS_PROJECT_ENV_FILE_WARNINGS=false

if [ ! -f "$PROJECT_ENV_FILE" ]; then
    error_project_env_file_missing
    HAS_PROJECT_ENV_FILE_WARNINGS=true
else
    check_project_env() {
        local arg_token=$1
        local arg_expected_value=$2

        # '^' matches the start of line so that if a value is commented out, it'll result in error
        local regex="^$arg_token=$arg_expected_value"

        if  ! grep -oq "$regex" "$PROJECT_ENV_FILE"; then
            error_project_env_field_missing "$arg_token"
            HAS_PROJECT_ENV_FILE_WARNINGS=true
        fi
    }

    match_any_word="\w*"

    # These tokens can match to any string
    check_project_env "$P_ENV_GITHUB_TOKEN" "$match_any_word"
    check_project_env "$P_ENV_SENTRY_AUTH_TOKEN" "$match_any_word"
    check_project_env "$P_ENV_BUILDKITE_TOKEN" "$match_any_word"

    # These values are set per project in configuration section and the value is not a secret
    check_project_env "$P_ENV_SENTRY_ORG_SLUG" "$P_ENV_SENTRY_ORG_SLUG_VALUE"
    check_project_env "$P_ENV_SENTRY_PROJECT_SLUG" "$P_ENV_SENTRY_PROJECT_SLUG_VALUE"
fi

if [ "$HAS_PROJECT_ENV_FILE_WARNINGS" == true ]; then
    warning_project_env_file_contents
    echo "$LOG_SEPERATOR"

    HAS_WARNINGS=true
fi

# ---------------------------------------------------------------------------------
# 3. Wrapping Up
# ---------------------------------------------------------------------------------

if [ "$HAS_WARNINGS" == true ]; then
    echo "Please address the warnings and re-run this check before continuing with the release.
If you need help, please contact @owl-team in #platform9 Slack channel."
else
    echo "Everything looks good, good luck with the release!"
fi
