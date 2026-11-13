# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

# Runs the production `should-skip-job.sh` against a throwaway PR whose base is a local `origin/trunk`.
class ShouldSkipJobFixture
  SCRIPT = File.expand_path('../../../.buildkite/commands/should-skip-job.sh', __dir__)

  def self.pr_changed_files
    ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |dir| File.join(dir, 'pr_changed_files') }.find { |path| File.executable?(path) }
  end

  def initialize
    @directory = File.realpath(Dir.mktmpdir('should-skip-job'))
    @checkout = File.join(@directory, 'checkout')
    install_buildkite_agent_stub
    prepare_repository
  end

  def close
    FileUtils.remove_entry(@directory)
  end

  def skips?(job_type, changed_files)
    git('checkout', '-q', '-B', 'pr', 'origin/trunk')
    changed_files.each { |path| write(path) }
    git('add', '--force', '--', *changed_files)
    git('commit', '-q', '-m', 'PR change')

    output, status = Open3.capture2e(environment, '/bin/bash', '.buildkite/commands/should-skip-job.sh', '--job-type', job_type, chdir: @checkout)
    raise "should-skip-job.sh errored (#{status.exitstatus}):\n#{output}" unless [0, 1].include?(status.exitstatus)

    status.exitstatus.zero?
  end

  private

  def environment
    {
      'PATH' => [File.join(@directory, 'bin'), File.dirname(self.class.pr_changed_files), ENV.fetch('PATH')].join(File::PATH_SEPARATOR),
      'BUILDKITE_PULL_REQUEST' => '1',
      'BUILDKITE_PULL_REQUEST_BASE_BRANCH' => 'trunk'
    }
  end

  def install_buildkite_agent_stub
    agent = File.join(@directory, 'bin', 'buildkite-agent')
    FileUtils.mkdir_p(File.dirname(agent))
    File.write(agent, "#!/bin/bash\ncat > /dev/null\n")
    File.chmod(0o755, agent)
  end

  def prepare_repository
    origin = File.join(@directory, 'origin.git')
    run('git', 'init', '-q', '--bare', '--initial-branch=trunk', origin)
    run('git', 'clone', '-q', origin, @checkout)
    git('config', 'user.email', 'test@example.com')
    git('config', 'user.name', 'Test')
    FileUtils.mkdir_p(File.join(@checkout, '.buildkite/commands'))
    FileUtils.cp(SCRIPT, File.join(@checkout, '.buildkite/commands'))
    git('add', '.')
    git('commit', '-q', '-m', 'Base')
    git('push', '-q', 'origin', 'HEAD:trunk')
  end

  def write(path)
    absolute = File.join(@checkout, path)
    FileUtils.mkdir_p(File.dirname(absolute))
    File.write(absolute, "change\n")
  end

  def git(*)
    run('git', '-C', @checkout, *)
  end

  def run(*command)
    output, status = Open3.capture2e(*command)
    raise "#{command.join(' ')} failed:\n#{output}" unless status.success?

    output
  end
end
