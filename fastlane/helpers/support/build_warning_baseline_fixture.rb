# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require_relative 'build_warning_baseline_repository'
require_relative 'build_warning_baseline_environment'

# Runs the production baseline script with real parsing and isolated services.
class BuildWarningBaselineFixture
  include BuildWarningBaselineRepository
  include BuildWarningBaselineEnvironment

  COMMANDS = File.expand_path('../../../.buildkite/commands', __dir__)
  HELPER = File.expand_path('../build_warnings_helper.rb', __dir__)

  attr_reader :base_commit

  def initialize
    @directory = File.realpath(Dir.mktmpdir('build-warning-baseline'))
    @bin = File.join(@directory, 'bin')
    @checkout = File.join(@directory, 'checkout')
    FileUtils.mkdir_p([local_cache, shared_cache, uploads])
    install_tools
    prepare_repository
    install_scripts
  end

  def close
    FileUtils.remove_entry(@directory)
  end

  def install_scripts
    commands = File.join(@checkout, '.buildkite/commands')
    %w[build-warning-baseline.sh count-build-warnings.rb].each { |name| FileUtils.cp(File.join(COMMANDS, name), commands) }
    FileUtils.mkdir_p(File.join(@checkout, 'fastlane/helpers'))
    FileUtils.cp(HELPER, File.join(@checkout, 'fastlane/helpers'))
    skip = File.join(commands, 'should-skip-job.sh')
    File.write(skip, "#!/bin/bash\nexit 1\n")
    File.chmod(0o755, skip)
  end

  def run
    Open3.capture3(environment, '/bin/bash', '.buildkite/commands/build-warning-baseline.sh',
                   chdir: @checkout, unsetenv_others: true)
  end

  def calls(command)
    return [] unless File.file?(calls_path)

    File.readlines(calls_path).map { |line| JSON.parse(line) }.select { |call| call.fetch('command') == command }
  end

  def report
    JSON.parse(File.read(File.join(@checkout, 'base-build-warnings.json')))
  end

  def cached_report
    { 'baseline_commit' => @base_commit, 'scope' => 'owned_app_and_modules', 'count' => 0, 'warnings' => [] }
  end

  def cache_key
    parser = File.read(File.join(COMMANDS, 'count-build-warnings.rb')) + File.read(HELPER)
    parts = [@base_commit, 'test-image', 'owned_app_and_modules', Digest::SHA1.hexdigest(parser),
             Digest::SHA1.file(File.join(COMMANDS, 'build-warning-baseline.sh')).hexdigest, 'test-epoch']
    Digest::SHA1.hexdigest("#{parts.join("\n")}\n")
  end

  def local_cache_path
    File.join(local_cache, "#{cache_key}.json")
  end

  def shared_cache_path
    File.join(shared_cache, "build-warning-baseline-#{cache_key}.json")
  end

  def uploaded_reports
    Dir.glob(File.join(uploads, '*.json')).map { |path| JSON.parse(File.read(path)) }
  end

  def worktrees
    git(@checkout, 'worktree', 'list', '--porcelain').lines.grep(/^worktree /)
  end
end
