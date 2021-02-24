source 'https://rubygems.org'

gem 'rake'
gem 'cocoapods', '~> 1.10'
gem 'xcpretty-travis-formatter'
gem 'dotenv'
gem 'xcode-install'
gem 'fastlane', '~> 2'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
