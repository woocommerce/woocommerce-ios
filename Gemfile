# frozen_string_literal: true

source 'https://rubygems.org'

group :screenshots, optional: true do
  gem 'rmagick', '~> 4.1'
end

# fix activesupport to < 7.1.0 due to a bug with Cocoapods (https://github.com/CocoaPods/CocoaPods/issues/12081)
gem 'activesupport', '< 7.1.0'
# 1.13.x and higher, but less than 2.x, starting from 1.13.0
gem 'cocoapods', '~> 1.13', '>= 1.13.0'
gem 'cocoapods-catalyst-support', '~> 0.1'
gem 'dotenv'
gem 'fastlane', '~> 2'
gem 'fastlane-plugin-appcenter', '~> 2.0'
gem 'fastlane-plugin-sentry', '~> 1.0'
# The 9.0.1 version includes a fix for the pot file generation.
# We want to resolve to any 9.x compatible version, _starting from_ 9.0.1.
# Using '~> 9.0.1' would resolve to 9.0.x compatible version, missing out on any new feature release.
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 9.0', '>= 9.0.1'
gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.56'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
gem 'xcpretty-travis-formatter'

gem 'danger-dangermattic', git: 'https://github.com/Automattic/dangermattic'
