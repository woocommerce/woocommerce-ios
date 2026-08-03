# frozen_string_literal: true

source 'https://rubygems.org'

group :screenshots, optional: true do
  # Capped below 7: the wpmreleasetoolkit PromoScreenshots helper still targets
  # rmagick 5.x and breaks on 7. See AINFRA-2482.
  gem 'rmagick', '>= 4.1', '< 7'
end

gem 'danger-dangermattic', '~> 1.4'
gem 'dotenv'
gem 'fastlane', '~> 2.237'
gem 'fastlane-plugin-firebase_app_distribution', '~> 1.0'
gem 'fastlane-plugin-sentry', '~> 2.6'
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'git@github.com:wordpress-mobile/release-toolkit', branch: ''
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 14.11'
# To avoid errors like:
#
# SSL_connect returned=1 errno=0 peeraddr=3.5.132.155:443 state=error: certificate verify failed (unable to get certificate CRL)
#
# See https://github.com/ruby/openssl/issues/949
gem 'openssl', '~> 4.0'
gem 'rake', '~> 13.4'
gem 'rubocop', '~> 1.88'
gem 'rubocop-rake', '~> 0.6'
gem 'xcode-install'
