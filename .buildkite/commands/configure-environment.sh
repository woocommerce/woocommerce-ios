#!/bin/bash -eu

echo '--- :git: Configure Git for Release Management'
.buildkite/commands/configure-git-for-release-management.sh

echo '--- :ruby: Setup Ruby Tools'
install_gems
