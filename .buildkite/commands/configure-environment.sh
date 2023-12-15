#!/bin/bash -eu

echo '--- :git: Configure Git for release management'
.buildkite/commands/configure-git-for-release-management.sh

echo '--- :ruby: Setup Ruby tools'
restore_cache "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"
install_gems
