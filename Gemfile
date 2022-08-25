# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.10'
gem 'cocoapods-catalyst-support', '~> 0.1'
gem 'dotenv'
# gem 'fastlane', '~> 2'
#
# Starting a binary tree search to see if the issue is new...
# gem 'fastlane', '~> 2.200.0' - fail
# gem 'fastlane', '~> 2.190.0' - fail
# gem 'fastlane', '~> 2.180.0' - fail
# gem 'fastlane', '~> 2.170.0' <- giving up here, still failing
#
# Local setup for debugging
gem 'fastlane', path: "#{Dir.home}/Developer/oss/fastlane"

gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.25'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
gem 'xcpretty-travis-formatter'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
