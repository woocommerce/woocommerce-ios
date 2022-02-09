# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.10'
gem 'cocoapods-catalyst-support', '~> 0.1'
gem 'dotenv'
gem 'fastlane', '~> 2'
gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.25'
gem 'xcode-install'
gem 'xcpretty-travis-formatter'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
