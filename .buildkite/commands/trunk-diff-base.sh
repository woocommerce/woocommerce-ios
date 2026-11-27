#!/usr/bin/env bash

set -euo pipefail

# Print the trunk comparison base, or exit nonzero when jobs should run fully.
# An operator-supplied base can cover a direct/failed/skipped push on webhook, API
# or triggered builds. Automatic webhook selection needs the complete push range.
[[ ${BUILDKITE_BRANCH:-} == trunk && ${BUILDKITE_PULL_REQUEST-false} == false &&
   -z ${BUILDKITE_TAG:-} && ${CI_FULL_BUILD:-} != 1 ]] || exit 1

if [[ -n ${CI_CHANGED_FILES_BASE:-} ]]; then
  case ${BUILDKITE_SOURCE:-} in webhook|api|trigger_job) ;; *) exit 1 ;; esac
  base=$(git rev-parse --quiet --verify --end-of-options "${CI_CHANGED_FILES_BASE}^{commit}") || exit 1
else
  [[ ${BUILDKITE_SOURCE:-} == webhook ]] || exit 1
  # Woo only accepts merge commits. An ordinary commit needs an explicit base.
  git rev-parse --quiet --verify 'HEAD^2' >/dev/null || exit 1

  head=$(git rev-parse HEAD)
  base=$(buildkite-agent meta-data get buildkite:webhook | jq -er --arg head "$head" '
    select(.ref == "refs/heads/trunk" and .after == $head)
    | .before | select(type == "string" and test("^[0-9a-f]{40}$"))
  ') || exit 1
  # A skipped previous push may contain code the current push does not touch.
  previous_message=$(git log -1 --format=%B "$base" --) || exit 1
  skip_ci='\[(ci[ -]skip|skip[ -]ci)\]'
  shopt -s nocasematch
  [[ ! $previous_message =~ $skip_ci ]] || exit 1
fi

git merge-base --is-ancestor "$base" HEAD || exit 1
printf '%s\n' "$base"
