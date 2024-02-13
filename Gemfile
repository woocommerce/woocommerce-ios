# frozen_string_literal: true

source 'https://rubygems.org'

group :screenshots, optional: true do
  gem 'rmagick', '~> 4.1'
end

gem 'cocoapods', '~> 1.14'
gem 'cocoapods-catalyst-support', '~> 0.1'
gem 'dotenv'
# 2.217.0 includes a fix for Xcode 15 test results parsing in CI
gem 'fastlane', '~> 2.217'
gem 'fastlane-plugin-appcenter', '~> 2.0'
gem 'fastlane-plugin-sentry', '~> 1.0'
# This comment avoids typing to switch to a development version for testing.
#
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'git@github.com:wordpress-mobile/release-toolkit', branch: ''
#
# The 9.0.1 version includes a fix for the pot file generation.
# We want to resolve to any 9.x compatible version, _starting from_ 9.0.1.
# Using '~> 9.0.1' would resolve to 9.0.x compatible version, missing out on any new feature release.
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 9.3'
gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.60'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
gem 'xcpretty-travis-formatter'

gem 'danger-dangermattic', '~> 1.0'
