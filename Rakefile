# frozen_string_literal: true

require 'fileutils'
require 'rake/clean'

PROJECT_DIR = __dir__
XCODE_WORKSPACE = 'WooCommerce.xcworkspace'

desc 'Install required dependencies'
task dependencies: %w[dependencies:check]

namespace :dependencies do
  task check: %w[bundler:check bundle:check credentials:apply]

  namespace :bundler do
    task :check do
      Rake::Task['dependencies:bundler:install'].invoke unless command?('bundler')
    end

    task :install do
      puts 'Bundler not found in PATH, installing to vendor'
      ENV['GEM_HOME'] = File.join(PROJECT_DIR, 'vendor', 'gems')
      ENV['PATH'] = File.join(PROJECT_DIR, 'vendor', 'gems', 'bin') + ":#{ENV.fetch('PATH', nil)}"
      sh 'gem install bundler' unless command?('bundler')
    end
    CLOBBER << 'vendor/gems'
  end

  namespace :bundle do
    task :check do
      sh 'bundle check --path=${BUNDLE_PATH:-vendor/bundle} > /dev/null', verbose: false do |ok, _res|
        next if ok

        # bundle check exits with a non zero code if install is needed
        dependency_failed('Bundler')
        Rake::Task['dependencies:bundle:install'].invoke
      end
    end

    task :install do
      sh 'bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}'
    end
    CLOBBER << 'vendor/bundle'
    CLOBBER << '.bundle'
  end

  namespace :credentials do
    task :apply do
      next unless Dir.exist?(File.join(Dir.home, '.mobile-secrets/.git')) || ENV.key?('CONFIGURE_ENCRYPTION_KEY')

      sh('FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_ENV_PRINTER=1 bundle exec fastlane run configure_apply force:true')
    end
  end
end

CLOBBER << 'vendor'

desc 'Mocks'
task :mocks do
  sh './API-Mocks/scripts/start.sh'
end

desc 'Checks the source for style errors'
task :lint do
  swiftlint
end

namespace :lint do
  desc 'Automatically corrects style errors where possible'
  task :autocorrect do
    swiftlint(additional_args: ['--fix'])
  end

  desc 'Check the Xcode project for inline build settings'
  task :build_settings do
    run_in_swift_package(dir: 'BuildSettingsPolice', cmd: 'swift run -c release build-settings-police check ../WooCommerce/WooCommerce.xcodeproj --project')
  end
end

desc 'Open the project in Xcode'
task xcode: [:dependencies] do
  sh "open #{XCODE_WORKSPACE}"
end

desc 'Run all code generation tasks'
task :generate do
  # See note in BuildTools/.sourcery.yml for why we call without arguments
  run_package_plugin(cmd: 'sourcery-command --disableCache')
end

def command?(command)
  system("which #{command} > /dev/null 2>&1")
end

def dependency_failed(component)
  msg = "#{component} dependencies missing or outdated. "
  if ENV['DRY_RUN']
    msg += 'Run rake dependencies to install them.'
    raise msg
  else
    msg += 'Installing...'
    puts msg
  end
end

def swiftlint(additional_args: [])
  run_package_plugin(cmd: "swiftlint --working-directory .. --quiet #{additional_args.join(' ')}")
end

def run_package_plugin(cmd:)
  run_in_build_tools(cmd: "swift package plugin --allow-writing-to-directory .. --allow-writing-to-package-directory #{cmd}")
end

# We could use more idiomatic Ruby here, with `Dir.chdir`, but leaving as raw shell commands for when we'll drop Ruby and rake for tooling.
def run_in_build_tools(cmd:)
  run_in_swift_package(dir: 'BuildTools', cmd: cmd)
end

def run_in_swift_package(dir:, cmd:)
  sh "pushd #{dir} && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && #{cmd} && popd" do |ok, status|
    exit(status.exitstatus || 1) unless ok
  end
end
