# frozen_string_literal: true

source 'https://rubygems.org'

group :screenshots, optional: true do
  gem 'rmagick', '~> 4.1'
end

gem 'danger-dangermattic', '~> 1.2'
gem 'dotenv'
gem 'fastlane', '~> 2.228'
gem 'fastlane-plugin-firebase_app_distribution', '~> 0.10'
gem 'fastlane-plugin-sentry', '~> 1.0'
gem 'fastlane-plugin-wpmreleasetoolkit', git: 'https://github.com/wordpress-mobile/release-toolkit', branch: 'add/openai-ask-tool-support'
# gem 'fastlane-plugin-wpmreleasetoolkit', '~> 14.0'
# To avoid errors like:
#
# SSL_connect returned=1 errno=0 peeraddr=3.5.132.155:443 state=error: certificate verify failed (unable to get certificate CRL)
#
# See https://github.com/ruby/openssl/issues/949
gem 'openssl', '~> 4.0'
gem 'rake', '~> 12.3'
gem 'rubocop', '~> 1.65'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
