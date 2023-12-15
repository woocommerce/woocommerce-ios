#!/bin/bash -eu

echo '--- :git: Configure Git for release management'
.buildkite/commands/configure-git-for-release-management.sh

echo '--- :ruby: Setup Ruby tools'
install_gems
