# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'support/build_warning_baseline_fixture'

# Exercises baseline caching and ref selection through the production script.
class BuildWarningBaselineTest < Minitest::Test
  def setup
    @fixture = BuildWarningBaselineFixture.new
  end

  def teardown
    @fixture&.close
  end

  def run_baseline
    output, error, status = @fixture.run
    assert status.success?, "#{output}\n#{error}"
  end

  def assert_uploads
    assert_equal 2, @fixture.uploaded_reports.length
    assert(@fixture.uploaded_reports.all? { |report| report == @fixture.report })
  end

  def assert_rebuilt_report
    report = @fixture.report
    assert_equal 1, @fixture.calls('bundle').length
    assert_equal 'rebuilt', report.fetch('baseline_cache_source')
    assert_equal @fixture.base_commit, report.fetch('baseline_commit')
  end

  def assert_persisted_report
    report = @fixture.report
    assert_equal report, JSON.parse(File.read(@fixture.local_cache_path))
    assert_equal report, JSON.parse(File.read(@fixture.shared_cache_path))
  end

  def test_local_cache_hit_avoids_build_and_uploads_report
    # Given
    File.write(@fixture.local_cache_path, JSON.generate(@fixture.cached_report))

    # When
    run_baseline

    # Then
    assert_empty @fixture.calls('bundle')
    assert_empty @fixture.calls('restore_cache')
    assert_equal 'local-cache', @fixture.report.fetch('baseline_cache_source')
    assert File.file?(@fixture.shared_cache_path)
    assert_uploads
  end

  def test_shared_cache_hit_avoids_build_and_warms_local_cache
    # Given
    File.write(@fixture.shared_cache_path, JSON.generate(@fixture.cached_report))

    # When
    run_baseline

    # Then
    assert_empty @fixture.calls('bundle')
    assert_equal 'shared-cache', @fixture.report.fetch('baseline_cache_source')
    assert_equal @fixture.cached_report, JSON.parse(File.read(@fixture.local_cache_path))
    assert_uploads
  end

  def test_cache_miss_builds_parses_persists_and_uploads_then_cleans_worktree
    # Given: neither cache contains a report.
    # When
    run_baseline

    # Then
    assert_rebuilt_report
    assert_equal 1, @fixture.calls('baseline-setup').length
    assert_persisted_report
    assert_equal 1, @fixture.worktrees.length
    assert_uploads
  end

  def test_rebuild_counts_warning_log_using_the_base_worktree_path
    # Given: the build stub emits an absolute-path warning in the base worktree.
    # When
    run_baseline

    # Then
    report = @fixture.report
    assert_equal 'release/testing', report.fetch('base_branch')
    assert_equal 1, report.fetch('count')
    assert_equal 'baseline fixture', report.fetch('warnings').first.fetch('message')
  end

  def test_invalid_local_cache_uses_valid_shared_cache
    # Given
    File.write(@fixture.local_cache_path, 'invalid JSON')
    File.write(@fixture.shared_cache_path, JSON.generate(@fixture.cached_report))

    # When
    run_baseline

    # Then
    assert_empty @fixture.calls('bundle')
    assert_equal 'shared-cache', @fixture.report.fetch('baseline_cache_source')
    assert_uploads
  end

  def test_wrong_commit_in_shared_cache_rebuilds
    # Given
    invalid = @fixture.cached_report.merge('baseline_commit' => 'wrong-commit')
    File.write(@fixture.shared_cache_path, JSON.generate(invalid))

    # When
    run_baseline

    # Then
    assert_rebuilt_report
    assert_uploads
  end

  def test_restricted_fetch_mapping_refreshes_stale_base_tracking_ref
    # Given
    new_base = @fixture.advance_base_with_restricted_mapping

    # When
    run_baseline

    # Then
    assert_equal new_base, @fixture.report.fetch('baseline_commit')
  end

  def test_restricted_fetch_mapping_creates_missing_base_tracking_ref
    # Given
    new_base = @fixture.advance_base_with_restricted_mapping
    @fixture.remove_base_tracking_ref

    # When
    run_baseline

    # Then
    assert_equal new_base, @fixture.report.fetch('baseline_commit')
  end
end
