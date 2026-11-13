# frozen_string_literal: true

# Exposes only local fixture tools to child processes, with Git restricted to files.
module BuildWarningBaselineEnvironment
  def environment
    {
      'PATH' => "#{@bin}:/usr/bin:/bin", 'TMPDIR' => @directory,
      'GIT_ALLOW_PROTOCOL' => 'file', 'GIT_CONFIG_NOSYSTEM' => '1', 'GIT_CONFIG_GLOBAL' => File::NULL,
      'BUILDKITE_PULL_REQUEST' => '123', 'BUILDKITE_PULL_REQUEST_BASE_BRANCH' => 'release/testing',
      'IMAGE_ID' => 'test-image', 'BUILD_WARNING_BASELINE_CACHE_EPOCH' => 'test-epoch',
      'BUILD_WARNING_BASELINE_CACHE_DIR' => local_cache,
      'BASELINE_TEST_SHARED_CACHE' => shared_cache, 'BASELINE_TEST_CALLS' => calls_path,
      'BASELINE_TEST_UPLOADS' => uploads
    }
  end

  def install_tools
    FileUtils.mkdir_p(@bin)
    File.symlink(RbConfig.ruby, File.join(@bin, 'ruby'))
    install_jq
    stub = File.join(@bin, 'baseline-tool-stub')
    File.write(stub, "#!/usr/bin/env ruby\n#{File.read(File.join(__dir__, 'build_warning_baseline_tool_stub.rb'))}")
    File.chmod(0o755, stub)
    %w[baseline-setup bundle restore_cache save_cache upload_artifact buildkite-agent curl gh aws ssh wget].each do |command|
      File.symlink(stub, File.join(@bin, command))
    end
  end

  def install_jq
    jq = ENV.fetch('PATH').split(File::PATH_SEPARATOR).map { |directory| File.join(directory, 'jq') }.find { |path| File.executable?(path) }
    raise 'jq is required for baseline tests' unless jq

    File.symlink(jq, File.join(@bin, 'jq'))
  end

  def local_cache
    File.join(@directory, 'local-cache')
  end

  def shared_cache
    File.join(@directory, 'shared-cache')
  end

  def calls_path
    File.join(@directory, 'calls.jsonl')
  end

  def uploads
    File.join(@directory, 'uploads')
  end
end
