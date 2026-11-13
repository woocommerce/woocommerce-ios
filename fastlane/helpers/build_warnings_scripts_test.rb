# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Isolated integration tests for warning comparison and PR comment delivery.
class BuildWarningsScriptsTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  COMMANDS_DIR = File.expand_path('../../.buildkite/commands', __dir__)
  CURRENT_COMMIT = 'a' * 40
  OTHER_COMMIT = 'b' * 40
  CURRENT_REPORT = 'build-warnings.json'
  BASELINE_REPORT = 'base-build-warnings.json'
  BUILD_URL = 'https://buildkite.com/automattic/woocommerce-ios/builds/123'

  def setup
    @directory = Dir.mktmpdir('build-warnings-scripts')
    @bin = File.join(@directory, 'bin')
    @artifacts = File.join(@directory, 'artifacts')
    @calls_path = File.join(@directory, 'calls.jsonl')
    FileUtils.mkdir_p([@bin, @artifacts])
    install_stubs
    @environment = {
      'PATH' => "#{@bin}:/usr/bin:/bin",
      'BUILDKITE_PULL_REQUEST' => '17456',
      'BUILDKITE_REPO' => 'git@github.com:woocommerce/woocommerce-ios.git',
      'BUILDKITE_PULL_REQUEST_REPO' => 'git@github.com:woocommerce/woocommerce-ios.git',
      'BUILDKITE_PULL_REQUEST_BASE_BRANCH' => 'trunk',
      'BUILDKITE_COMMIT' => CURRENT_COMMIT,
      'BUILDKITE_BUILD_URL' => BUILD_URL,
      'WARNING_TEST_CALLS' => @calls_path,
      'WARNING_TEST_ARTIFACTS' => @artifacts,
      'WARNING_TEST_PR_RESPONSE' => JSON.generate('head' => { 'sha' => CURRENT_COMMIT })
    }
    write_report(CURRENT_REPORT, report('existing warning', 'new warning'))
    write_report(BASELINE_REPORT, report('existing warning'))
  end

  def teardown
    FileUtils.remove_entry(@directory) if @directory
  end

  def test_comparator_when_warnings_increase_then_prints_comment_and_succeeds
    # Given: setup provides a report with one new warning.
    # When
    stdout, stderr, status = compare_reports

    # Then
    assert status.success?, stderr
    assert_includes stdout, '1 new build warning'
  end

  def test_comparator_when_comparison_is_clean_then_prints_nothing_and_succeeds
    # Given
    write_report(CURRENT_REPORT, report('existing warning'))

    # When
    stdout, stderr, status = compare_reports

    # Then
    assert status.success?, stderr
    assert_empty stdout
  end

  def test_comparator_when_report_is_unavailable_then_fails_without_comment
    unavailable_reports.each do |name, value|
      # Given
      write_report(CURRENT_REPORT, value)

      # When
      stdout, stderr, status = compare_reports

      # Then
      assert_equal 1, status.exitstatus, name
      assert_empty stdout, name
      refute_empty stderr, name
    end
  end

  def test_commenter_when_warnings_increase_then_posts_with_commit_and_build_provenance
    # Given: setup provides a current-head build with one new warning.
    # When
    run_commenter

    # Then
    assert_equal 1, calls('comment_on_pr').length
    assert_equal ['--id', 'build-warning-count'], comment_arguments.first(2)
    assert_includes comment_body, '1 new build warning'
    assert_match(/Built commit: `?#{CURRENT_COMMIT}`?/, comment_body)
    assert_includes comment_body, BUILD_URL
    assert_github_request
  end

  def test_commenter_when_comparison_is_clean_then_deletes_existing_comment
    # Given
    write_report(CURRENT_REPORT, report('existing warning'))

    # When
    run_commenter

    # Then
    assert_equal([['--id', 'build-warning-count', '--if-exist', 'delete']], calls('comment_on_pr').map { |call| call.fetch('arguments') })
  end

  def test_commenter_when_current_artifact_is_missing_then_posts_unavailable
    # Given
    FileUtils.rm(File.join(@artifacts, CURRENT_REPORT))

    # When
    run_commenter

    # Then
    assert_unavailable_comment
  end

  def test_commenter_when_baseline_artifact_is_missing_then_posts_unavailable
    # Given
    FileUtils.rm(File.join(@artifacts, BASELINE_REPORT))

    # When
    run_commenter

    # Then
    assert_unavailable_comment
  end

  def test_commenter_when_report_is_invalid_then_posts_unavailable
    unavailable_reports.each do |name, value|
      # Given
      write_report(CURRENT_REPORT, value)
      clear_calls

      # When
      run_commenter

      # Then
      assert_unavailable_comment(name)
    end
  end

  def test_commenter_when_toolkit_download_fails_then_uses_buildkite_artifacts
    # Given
    @environment['WARNING_TEST_TOOLKIT_DOWNLOAD_FAILS'] = 'true'

    # When
    run_commenter

    # Then
    assert_includes comment_body, '1 new build warning'
    assert_equal(2, calls('buildkite-agent').count { |call| call.fetch('arguments').first(2) == %w[artifact download] })
  end

  def test_commenter_when_build_is_stale_then_does_not_mutate_any_comment_state
    # Given
    @environment['WARNING_TEST_PR_RESPONSE'] = JSON.generate('head' => { 'sha' => OTHER_COMMIT })
    [report('existing warning', 'new warning'), report('existing warning'), 'invalid json'].each do |value|
      write_report(CURRENT_REPORT, value)
      clear_calls

      # When
      run_commenter

      # Then
      assert_empty calls('comment_on_pr')
    end
  end

  def test_commenter_when_latest_head_lookup_fails_then_does_not_mutate_comments
    # Given
    @environment['WARNING_TEST_GITHUB_FAILS'] = 'true'

    # When
    run_commenter

    # Then
    assert_empty calls('comment_on_pr')
  end

  def test_commenter_when_latest_head_response_is_invalid_then_does_not_mutate_comments
    ['invalid json', '{}', JSON.generate('head' => { 'sha' => 'null' })].each do |response|
      # Given
      @environment['WARNING_TEST_PR_RESPONSE'] = response
      clear_calls

      # When
      run_commenter

      # Then
      assert_empty calls('comment_on_pr')
    end
  end

  def test_commenter_when_build_commit_is_invalid_then_does_not_mutate_comments
    [nil, '', 'HEAD', 'invalid'].each do |commit|
      # Given
      @environment['BUILDKITE_COMMIT'] = commit
      clear_calls

      # When
      run_commenter

      # Then
      assert_empty calls('comment_on_pr')
    end
  end

  def test_commenter_when_checkout_is_merge_commit_then_uses_pull_request_head
    # Given
    @environment['BUILDKITE_COMMIT'] = OTHER_COMMIT
    @environment['BUILDKITE_PULL_REQUEST_HEAD_COMMIT'] = CURRENT_COMMIT

    # When
    run_commenter

    # Then
    assert_match(/Built commit: `?#{CURRENT_COMMIT}`?/, comment_body)
    refute_includes comment_body, OTHER_COMMIT
  end

  def test_commenter_when_build_was_intentionally_skipped_then_does_not_download_or_mutate
    # Given
    @environment['WARNING_TEST_SKIP_BUILD'] = 'true'

    # When
    run_commenter

    # Then
    assert_no_delivery_attempts
    assert_equal ['--all-match'], calls('pr_changed_files').first.fetch('arguments').first(1)
    refute(calls('buildkite-agent').any? { |call| call.fetch('arguments').first == 'artifact' })
  end

  def test_commenter_when_not_pull_request_then_does_not_use_external_tools
    # Given
    @environment['BUILDKITE_PULL_REQUEST'] = 'false'

    # When
    run_commenter

    # Then
    assert_empty calls
  end

  def test_commenter_when_comment_delivery_fails_then_remains_advisory
    # Given
    @environment['WARNING_TEST_COMMENT_FAILS'] = 'true'

    # When
    run_commenter

    # Then
    assert_equal 1, calls('comment_on_pr').length
  end

  private

  def report(*messages)
    warnings = messages.map do |message|
      { 'path' => 'WooCommerce/Classes/A.swift', 'line' => 10, 'column' => 1, 'message' => message, 'area' => 'WooCommerce/Classes' }
    end
    { 'count' => warnings.length, 'scope' => 'owned_app_and_modules', 'warnings' => warnings, 'breakdown' => [] }
  end

  def unavailable_reports
    {
      'invalid JSON' => 'invalid json',
      'invalid count' => report('new warning').merge('count' => 'one'),
      'missing scope' => report('new warning').except('scope'),
      'incompatible scope' => report('new warning').merge('scope' => 'all_warnings'),
      'missing warning entries' => report('new warning').except('warnings')
    }
  end

  def write_report(name, value)
    File.write(File.join(@artifacts, name), value.is_a?(String) ? value : JSON.generate(value))
  end

  def compare_reports
    run_script(RbConfig.ruby, File.join(COMMANDS_DIR, 'compare-build-warnings.rb'),
               File.join(@artifacts, CURRENT_REPORT), File.join(@artifacts, BASELINE_REPORT))
  end

  def run_commenter
    stdout, stderr, status = run_script('/bin/bash', File.join(COMMANDS_DIR, 'comment-build-warning-increase.sh'))
    assert status.success?, "#{stdout}\n#{stderr}"
    assert_empty calls.select { |call| %w[curl gh aws ssh wget].include?(call.fetch('command')) }, 'Unexpected external transport invoked'
    [stdout, stderr]
  end

  def run_script(*command)
    Open3.capture3(@environment, *command, chdir: @directory, unsetenv_others: true)
  end

  def calls(command = nil)
    recorded = File.exist?(@calls_path) ? File.readlines(@calls_path).map { |line| JSON.parse(line) } : []
    command ? recorded.select { |call| call.fetch('command') == command } : recorded
  end

  def clear_calls
    File.write(@calls_path, '')
  end

  def comment_arguments
    calls('comment_on_pr').last.fetch('arguments')
  end

  def comment_body
    calls('comment_on_pr').last.fetch('body')
  end

  def assert_unavailable_comment(message = nil)
    assert_equal 1, calls('comment_on_pr').length, message
    refute_includes comment_arguments, 'delete', message
    assert_match(/comparison unavailable/i, comment_body, message)
    assert_match(/Built commit: `?#{CURRENT_COMMIT}`?/, comment_body, message)
    assert_includes comment_body, BUILD_URL, message
  end

  def assert_github_request
    arguments = calls('github_api').last.fetch('arguments')
    assert_equal 'repos/woocommerce/woocommerce-ios/pulls/17456', arguments.first
    assert arguments.include?('--fail') || arguments.include?('--fail-with-body')
    assert_includes arguments, '--connect-timeout'
    assert_includes arguments, '--max-time'
  end

  def assert_no_delivery_attempts
    assert_empty calls('download_artifact')
    assert_empty calls('github_api')
    assert_empty calls('comment_on_pr')
  end

  def link_runtime_tools
    File.symlink(RbConfig.ruby, File.join(@bin, 'ruby'))
    jq = ENV.fetch('PATH').split(File::PATH_SEPARATOR).map { |directory| File.join(directory, 'jq') }.find { |path| File.executable?(path) }
    raise 'jq is required to test the Buildkite scripts' unless jq

    File.symlink(jq, File.join(@bin, 'jq'))
  end

  def install_stubs
    link_runtime_tools
    stub = File.join(@bin, 'warning-test-stub')
    File.write(stub, tool_stub)
    File.chmod(0o755, stub)
    %w[download_artifact buildkite-agent github_api comment_on_pr pr_changed_files curl gh aws ssh wget].each do |command|
      File.symlink(stub, File.join(@bin, command))
    end
  end

  def tool_stub
    <<~'RUBY'
      #!/usr/bin/env ruby
      require 'fileutils'
      require 'json'
      command = File.basename($PROGRAM_NAME)
      call = { command: command, arguments: ARGV }
      if command == 'comment_on_pr'
        argument = ARGV.last.to_s
        call[:body] = File.file?(argument) ? File.read(argument) : argument
      end
      File.open(ENV.fetch('WARNING_TEST_CALLS'), 'a') { |file| file.puts(JSON.generate(call)) }
      case command
      when 'pr_changed_files'
        exit(ENV['WARNING_TEST_SKIP_BUILD'] == 'true' ? 0 : 1)
      when 'github_api'
        exit 1 if ENV['WARNING_TEST_GITHUB_FAILS'] == 'true'
        abort 'Unexpected GitHub endpoint' unless ARGV.first == 'repos/woocommerce/woocommerce-ios/pulls/17456'
        response = ENV.fetch('WARNING_TEST_PR_RESPONSE')
        output = ARGV.index('--output')
        output ? File.write(ARGV.fetch(output + 1), response) : puts(response)
      when 'comment_on_pr'
        exit(ENV['WARNING_TEST_COMMENT_FAILS'] == 'true' ? 1 : 0)
      when 'download_artifact', 'buildkite-agent'
        if command == 'buildkite-agent' && ARGV.first == 'annotate'
          STDIN.read
          exit 0
        end
        exit 1 if command == 'download_artifact' && ENV['WARNING_TEST_TOOLKIT_DOWNLOAD_FAILS'] == 'true'
        name = command == 'download_artifact' ? ARGV.first : ARGV.fetch(2)
        abort 'Unexpected artifact path' unless %w[build-warnings.json base-build-warnings.json].include?(name)
        source = File.join(ENV.fetch('WARNING_TEST_ARTIFACTS'), name)
        exit 1 unless File.file?(source)
        FileUtils.cp(source, name)
      else
        abort "External transport #{command} is forbidden in tests"
      end
    RUBY
  end
end
