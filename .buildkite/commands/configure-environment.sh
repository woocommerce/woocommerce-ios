#!/bin/bash -eu

.buildkite/commands/configure-git-for-release-management.sh

restore_cache "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"
install_gems
