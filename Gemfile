# frozen_string_literal: true

source 'https://rubygems.org'

group :screenshots, optional: true do
  gem 'rmagick', '~> 4.1'
end

gem 'danger-dangermattic', '~> 1.2'
gem 'dotenv'
# 2.217.0 includes a fix for Xcode 15 test results parsing in CI
gem 'fastlane', '~> 2.228'
gem 'fastlane-plugin-firebase_app_distribution', '~> 0.10'
gem 'fastlane-plugin-sentry', '~> 1.0'
# This comment avoids typing to switch to a development version for testing.
#
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'git@github.com:wordpress-mobile/release-toolkit', branch: ''
#
# The '>= 13.5.1' after '~> 13.5' ensures that we resolve to any version compatible with 13.5 starting from 13.5.1
# Using '~> 13.5.1' would constrain us to 13.5.2, 13.5.3, etc. without ever going up to 13.6
# We need 13.5.1 because of a fix in fetching issues / PRs with a fine-grained GitHub token
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 13.5', '>= 13.5.1'
gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.65'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
gem 'xcpretty-travis-formatter'
