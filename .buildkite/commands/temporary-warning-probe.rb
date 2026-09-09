# frozen_string_literal: true

require 'json'
require 'open3'
require_relative '../../fastlane/helpers/build_warnings_helper'

# TEMP-only live transport probe. Reports are synthetic; no app build or production cache is used.
class TemporaryWarningProbe
  ROOT = File.expand_path('../..', __dir__)
  BRANCH = 'codex/temp-warning-ci-failure-recovery'
  REPOSITORY = 'woocommerce/woocommerce-ios'
  COMMENTER = File.join(__dir__, 'comment-build-warning-increase.sh')
  MARKER = '<!-- DO NOT REMOVE ci-toolkit-comment-identifier: build-warning-count -->'
  CURRENT = 'temp-warning-probe-current.json'
  BASELINE = 'temp-warning-probe-baseline.json'
  EMPTY = 'temp-warning-probe-empty.json'
  MISSING = 'temp-warning-probe-intentionally-absent.json'
  INITIAL = 'temp-warning-evidence-initial.json'

  def initialize
    @passed = []
    @commit = ENV.fetch('BUILDKITE_PULL_REQUEST_HEAD_COMMIT', ENV['BUILDKITE_COMMIT'])
  end

  def run(command)
    return render_locally if command == 'render'

    validate_context!
    @validated_context = true
    case command
    when 'seed' then seed
    when 'verify' then verify
    else raise 'Expected seed, verify, or render'
    end
  rescue StandardError => error
    warn "TEMP validation failed: #{error.message}"
    begin
      publish_summary("FAILED: #{error.message}") if command == 'verify' && @validated_context
    rescue StandardError => reporting_error
      warn "Could not publish failure evidence: #{reporting_error.message}"
    end
    raise
  end

  def invoke(*arguments, env: {})
    output, error, status = Open3.capture3(env, *arguments, chdir: ROOT)
    warn error unless error.empty?
    raise "#{arguments.first} failed (#{status.exitstatus}): #{output.strip}" unless status.success?

    output
  end

  def validate_context!
    raise 'This probe may only run on its TEMP branch' unless ENV['BUILDKITE_BRANCH'] == BRANCH
    raise 'Expected a numbered pull request' unless ENV.fetch('BUILDKITE_PULL_REQUEST', '').match?(/\A\d+\z/)
    raise 'Expected an immutable build commit' unless @commit.to_s.match?(/\A[0-9a-f]{40}\z/)

    expected_urls = ["git@github.com:#{REPOSITORY}.git", "https://github.com/#{REPOSITORY}.git", "https://github.com/#{REPOSITORY}",
                     "git://github.com/#{REPOSITORY}.git"]
    %w[BUILDKITE_REPO BUILDKITE_PULL_REQUEST_REPO].each do |key|
      raise "Unexpected #{key}" unless expected_urls.include?(ENV[key])
    end
    require_current_head!
  end

  def github(endpoint)
    JSON.parse(invoke('github_api', endpoint, '--fail', '--connect-timeout', '10', '--max-time', '30'))
  end

  def require_current_head!
    head = github("repos/#{REPOSITORY}/pulls/#{ENV.fetch('BUILDKITE_PULL_REQUEST')}").fetch('head').fetch('sha')
    raise 'TEMP probe is no longer the current PR head' unless head == @commit
  end

  def report(messages)
    warnings = messages.map do |message|
      { 'area' => 'Modules/Sources/Yosemite', 'path' => 'Modules/Sources/Yosemite/TemporarySyntheticProbe.swift',
        'line' => 1, 'column' => 1, 'message' => message }
    end
    { 'count' => warnings.length, 'scope' => BuildWarningsHelper::OWNED_SCOPE, 'warnings' => warnings, 'breakdown' => [],
      'baseline_commit' => @commit, 'baseline_cache_source' => 'TEMP-synthetic-no-cache' }
  end

  def fixtures
    { CURRENT => report(['TEMP synthetic existing warning', 'TEMP synthetic additional warning']),
      BASELINE => report(['TEMP synthetic existing warning']), EMPTY => report([]) }
  end

  def upload(name, data)
    File.write(File.join(ROOT, name), JSON.pretty_generate(data))
    invoke('upload_artifact', name)
    invoke('buildkite-agent', 'artifact', 'upload', name)
  end

  def comments
    endpoint = "repos/#{REPOSITORY}/issues/#{ENV.fetch('BUILDKITE_PULL_REQUEST')}/comments?per_page=100"
    github(endpoint).select { |comment| comment.fetch('body').include?(MARKER) }
                    .map { |comment| comment.slice('id', 'body', 'updated_at') }.sort_by { |comment| comment.fetch('id') }
  end

  def snapshot(phase)
    require_current_head!
    observed = comments
    upload("temp-warning-evidence-#{phase}.json", { phase: phase, commit: @commit, build_url: ENV['BUILDKITE_BUILD_URL'], comments: observed })
    observed
  end

  def compare(current = CURRENT, baseline = BASELINE, env: {})
    puts invoke('/bin/bash', COMMENTER, current, baseline, env: env)
  end

  def check(condition, description)
    raise description unless condition

    @passed << description
    puts "PASS: #{description}"
  end

  def expect_comment(observed, title, id: nil)
    check(observed.length == 1, 'Exactly one production warning comment exists')
    comment = observed.fetch(0)
    check(comment.fetch('body').include?(title), "Comment contains: #{title}")
    check(comment.fetch('body').include?(@commit), 'Comment identifies the current build commit')
    check(comment.fetch('id') == id, 'The production comment ID is unchanged') if id
    comment.fetch('id')
  end

  def seed
    fixtures.each { |name, data| upload(name, data) }
    compare
    expect_comment(snapshot('initial'), 'New build warnings detected')
    upload('temp-warning-seed-exit.json', { expected_exit_status: 42, reason: 'Intentional advisory dependency failure after seeding reports' })
    puts 'TEMP seed intentionally exits 42 now. The verification job must still execute.'
    exit 42
  end

  def verify
    outcome = invoke('buildkite-agent', 'step', 'get', 'outcome', '--step', 'temp-warning-seed').strip
    check(outcome == 'soft_failed', 'The real seed dependency soft-failed and verification still started')
    invoke('download_artifact', INITIAL)
    initial = JSON.parse(File.read(File.join(ROOT, INITIAL))).fetch('comments').fetch(0).fetch('id')
    missing_and_recovery(initial)
    stale_preserves_comment
    zero_baseline_and_cleanup
    publish_summary('PASSED')
  end

  def missing_and_recovery(initial)
    { 'missing-current' => [MISSING, BASELINE], 'missing-baseline' => [CURRENT, MISSING] }.each do |phase, arguments|
      compare(*arguments)
      expect_comment(snapshot(phase), 'Build warning comparison unavailable', id: initial)
      compare
      expect_comment(snapshot("#{phase}-recovered"), 'New build warnings detected', id: initial)
    end
  end

  def stale_environment
    older_commit = invoke('git', 'rev-parse', 'HEAD^').strip
    raise 'Could not identify a distinct parent commit for simulated stale execution' if older_commit == @commit

    { 'BUILDKITE_COMMIT' => older_commit, 'BUILDKITE_PULL_REQUEST_HEAD_COMMIT' => older_commit }
  end

  def stale_preserves_comment
    original = snapshot('before-simulated-stale')
    { 'warning' => [CURRENT, BASELINE], 'clean' => [BASELINE, BASELINE], 'unavailable' => [MISSING, BASELINE] }.each do |phase, arguments|
      compare(*arguments, env: stale_environment)
      observed = snapshot("simulated-stale-#{phase}")
      check(observed == original, "Simulated older-head #{phase} preserves comment ID, body and updated_at")
    end
  end

  def zero_baseline_and_cleanup
    compare(BASELINE, EMPTY)
    first = snapshot('first-warning-empty-baseline')
    expect_comment(first, '1 new build warning')
    body = first.fetch(0).fetch('body')
    location = BuildWarningsHelper.markdown_literal('Modules/Sources/Yosemite/TemporarySyntheticProbe.swift:1')
    message = BuildWarningsHelper.markdown_literal('TEMP synthetic existing warning')
    check(body.include?(location) && body.include?(message), 'First warning against an empty baseline includes its exact path, line and message')
    compare(EMPTY, EMPTY)
    check(snapshot('two-empty-reports').empty?, 'Two empty reports delete the production warning comment')
    compare(env: stale_environment)
    check(snapshot('simulated-stale-after-cleanup').empty?, 'Simulated older-head warning cannot recreate a deleted comment')
  end

  def publish_summary(result)
    require_current_head!
    body = [
      '## TEMP warning validation evidence', '', result, '', "Commit: `#{@commit}`", "[CI build](#{ENV.fetch('BUILDKITE_BUILD_URL')})", '',
      'Synthetic JSON reports, real Buildkite artifacts and GitHub comments. No Xcode build or production cache.', '',
      *@passed.uniq.map { |description| "- #{description}" }, '',
      'Stale executions override both commit variables with HEAD^; these are simulations, not actual older-build retries.',
      'The failed dependency uses production-style soft failure plus allow_dependency_failure; this does not isolate the latter flag.',
      'Per-phase JSON snapshots are attached to the CI build.'
    ].join("\n")
    path = File.join(ROOT, 'temp-warning-validation-summary.md')
    File.write(path, body)
    invoke('comment_on_pr', '--id', 'temp-warning-validation-evidence', path)
    upload('temp-warning-validation-summary.json', { result: result, commit: @commit, passed: @passed.uniq })
  end

  def render_locally
    result = BuildWarningsHelper.build_comment(current: fixtures.fetch(CURRENT), baseline: fixtures.fetch(BASELINE), base_branch: BRANCH,
                                              build_url: 'https://buildkite.com/automattic/woocommerce-ios/builds/TEMP',
                                              repository_url: "https://github.com/#{REPOSITORY}", report_path: CURRENT, baseline_report_path: BASELINE)
    raise 'Synthetic fixture failed to render' unless result.fetch(:comment).include?('1 new build warning')

    puts result.fetch(:comment)
  end
end

TemporaryWarningProbe.new.run(ARGV.fetch(0))
