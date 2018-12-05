source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '~> 1.5.2'
  gem 'cocoapods-repo-update', '0.0.3'
  gem 'xcpretty-travis-formatter'
  gem 'danger'
  gem 'danger-swiftlint'
  gem 'dotenv'
end


gem "fastlane"
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)