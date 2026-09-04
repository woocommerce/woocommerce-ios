# frozen_string_literal: true

# Pure-Ruby unit tests for BuildWarningsHelper. Uses Ruby's stdlib Minitest so
# no extra gems are required.
#
# Run:
#   ruby fastlane/helpers/build_warnings_helper_test.rb

require 'minitest/autorun'
require 'tmpdir'
require_relative 'build_warnings_helper'

# Unit tests for BuildWarningsHelper.
class BuildWarningsHelperTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  Helper = BuildWarningsHelper

  REPO_ROOT = '/agent/checkout'

  # --- normalize_repo_path -----------------------------------------------------

  def test_normalize_repo_path_strips_repo_root_prefix
    assert_equal 'WooCommerce/Classes/A.swift', Helper.normalize_repo_path("#{REPO_ROOT}/WooCommerce/Classes/A.swift", REPO_ROOT)
  end

  def test_normalize_repo_path_rejects_absolute_paths_outside_repo
    assert_nil Helper.normalize_repo_path('/Applications/Xcode.app/foo.swift', REPO_ROOT)
  end

  def test_normalize_repo_path_keeps_relative_paths_and_strips_dot_slash
    assert_equal 'Modules/Sources/Yosemite/B.swift', Helper.normalize_repo_path('./Modules/Sources/Yosemite/B.swift', REPO_ROOT)
  end

  # --- owned_warning_area ------------------------------------------------------

  def test_owned_warning_area_buckets_app_classes_subdirectories
    assert_equal 'WooCommerce/Classes/ViewRelated', Helper.owned_warning_area('WooCommerce/Classes/ViewRelated/Orders/A.swift')
    assert_equal 'WooCommerce/Classes', Helper.owned_warning_area('WooCommerce/Classes/AppDelegate.swift')
  end

  def test_owned_warning_area_buckets_modules_by_target
    assert_equal 'Modules/Sources/Yosemite', Helper.owned_warning_area('Modules/Sources/Yosemite/Stores/OrderStore.swift')
    assert_equal 'Modules/Tests/NetworkingTests', Helper.owned_warning_area('Modules/Tests/NetworkingTests/RemoteTests.swift')
  end

  def test_owned_warning_area_excludes_xcodeproj_and_unowned_paths
    assert_nil Helper.owned_warning_area('WooCommerce/WooCommerce.xcodeproj/project.pbxproj')
    assert_nil Helper.owned_warning_area('Podfile')
    assert_nil Helper.owned_warning_area('ld')
  end

  # --- count_warnings ----------------------------------------------------------

  def test_count_warnings_scopes_to_owned_paths_and_tracks_exclusions
    report = count_report(mixed_log_lines)

    assert_equal 2, report[:count]
    assert_equal 4, report[:total_warning_lines]
    assert_equal 2, report[:excluded_warning_lines]
    assert_equal [{ area: 'Modules/Sources/Yosemite', count: 1 }, { area: 'WooCommerce/Classes/ViewRelated', count: 1 }], report[:breakdown]
  end

  def test_count_warnings_strips_ansi_codes_and_parses_line_only_locations
    first = count_report(mixed_log_lines)[:warnings].first

    assert_equal 'Modules/Sources/Yosemite/B.swift', first[:path]
    assert_equal 100, first[:line]
    assert_nil first[:column]
    assert_equal 'colored warning', first[:message]
  end

  def test_count_warnings_parses_line_and_column
    report = count_report(["#{REPO_ROOT}/WooCommerce/Classes/A.swift:7:3: warning: msg"])
    warning = report[:warnings].first

    assert_equal 7, warning[:line]
    assert_equal 3, warning[:column]
  end

  def test_collect_log_files_supports_file_directory_and_missing_paths
    Dir.mktmpdir do |dir|
      log = File.join(dir, 'a.log')
      File.write(log, '')
      File.write(File.join(dir, 'b.txt'), '')
      File.write(File.join(dir, 'ignored.json'), '')

      assert_equal [log], Helper.collect_log_files(log)
      assert_equal(['a.log', 'b.txt'], Helper.collect_log_files(dir).map { |f| File.basename(f) })
      assert_nil Helper.collect_log_files(File.join(dir, 'missing'))
    end
  end

  # --- build_comment gating ----------------------------------------------------

  def test_net_increase_posts_comment_listing_the_new_warning
    current = report_fixture(warnings: [warning_fixture, warning_fixture(path: 'WooCommerce/Classes/ViewRelated/New.swift', message: 'new warning')])
    baseline = report_fixture(warnings: [warning_fixture])
    result = build_comment(current: current, baseline: baseline)

    body = result.fetch(:comment)
    assert_includes body, '## New build warnings detected'
    assert_includes body, 'This PR introduces **1 new build warning** not present on'
    assert_includes body, '`WooCommerce/Classes/ViewRelated/New.swift:10` | new warning'
    refute_includes body, 'Occurrences'
  end

  def test_traded_warnings_with_no_net_increase_still_post_a_comment
    current = report_fixture(warnings: [warning_fixture(path: 'WooCommerce/Classes/ViewRelated/New.swift', message: 'new warning')])
    baseline = report_fixture(warnings: [warning_fixture])
    result = build_comment(current: current, baseline: baseline)

    body = result.fetch(:comment)
    assert_includes body, 'net change **0**'
    assert_includes body, '`WooCommerce/Classes/ViewRelated/New.swift:10` | new warning'
  end

  def test_decrease_without_exact_additions_skips
    current = report_fixture(warnings: [])
    baseline = report_fixture(warnings: [warning_fixture])
    result = build_comment(current: current, baseline: baseline)

    assert_match(/did not increase/, result.fetch(:skip))
  end

  def test_line_number_shifts_alone_are_not_flagged
    current = report_fixture(warnings: [warning_fixture(line: 99)])
    baseline = report_fixture(warnings: [warning_fixture(line: 10)])
    result = build_comment(current: current, baseline: baseline)

    assert result.key?(:skip)
  end

  def test_duplicate_log_entries_are_grouped_with_occurrence_counts
    new_warning = warning_fixture(path: 'WooCommerce/Classes/ViewRelated/New.swift', message: 'new warning')
    current = report_fixture(warnings: [warning_fixture, new_warning, new_warning])
    baseline = report_fixture(warnings: [warning_fixture])
    body = build_comment(current: current, baseline: baseline).fetch(:comment)

    assert_includes body, '<summary>New warnings: 1 (2 entries in the build log)</summary>'
    assert_includes body, '| Occurrences | File | Warning |'
    assert_includes body, '| 2 | `WooCommerce/Classes/ViewRelated/New.swift:10` | new warning |'
  end

  def test_count_increase_without_warning_details_falls_back_to_count_comparison
    current = report_fixture(count: 5, warnings: nil)
    baseline = report_fixture(count: 3, warnings: nil)
    body = build_comment(current: current, baseline: baseline).fetch(:comment)

    assert_includes body, 'This PR raises the build warning count to **5**, up from **3**'
    assert_includes body, '_Exact additional warning details are unavailable because one report does not include warning entries._'
  end

  def test_scope_mismatch_skips
    current = report_fixture
    baseline = report_fixture(scope: 'another_scope')
    result = build_comment(current: current, baseline: baseline)

    assert_match(/does not match current scope/, result.fetch(:skip))
  end

  def test_missing_current_scope_skips
    result = build_comment(current: report_fixture(scope: nil), baseline: report_fixture)

    assert_match(/missing a scope/, result.fetch(:skip))
  end

  def test_malformed_counts_raise
    assert_raises(ArgumentError) { build_comment(current: report_fixture(count: 'three'), baseline: report_fixture) }
    assert_raises(ArgumentError) { build_comment(current: report_fixture, baseline: report_fixture(count: nil, warnings: [warning_fixture] * 3)) }
  end

  # --- comment content ---------------------------------------------------------

  def test_baseline_label_links_the_merge_base_commit_and_converts_ssh_remotes
    label = Helper.baseline_label(
      baseline: { 'baseline_commit' => 'abc123def4567890' },
      base_branch: 'trunk',
      repository_url: 'git@github.com:woocommerce/woocommerce-ios.git'
    )

    assert_equal 'PR base `trunk` at [abc123def456](https://github.com/woocommerce/woocommerce-ios/commit/abc123def4567890)', label
  end

  def test_comment_includes_area_breakdown_and_caveats
    current = report_fixture(count: 2, warnings: [warning_fixture, warning_fixture(path: 'WooCommerce/Classes/ViewRelated/New.swift', message: 'new warning')],
                             breakdown: [{ 'area' => 'WooCommerce/Classes/ViewRelated', 'count' => 2 }])
    baseline = report_fixture(warnings: [warning_fixture], breakdown: [{ 'area' => 'WooCommerce/Classes/ViewRelated', 'count' => 1 }])
    body = build_comment(current: current, baseline: baseline).fetch(:comment)

    assert_includes body, '<summary>Area breakdown: 1 area with higher warning counts</summary>'
    assert_includes body, '| `WooCommerce/Classes/ViewRelated` | 2 | 1 | +1 |'
    assert_includes body, 'Artifacts tab of the [CI build](https://buildkite.example/builds/1)'
    assert_includes body, '- Baseline source: `local-cache`'
    assert_includes body, 'renaming or moving a file can report its pre-existing warnings as new'
    assert_includes body, 'Please consider removing the new warnings before merging.'
  end

  def test_markdown_escape_neutralizes_table_breaking_characters
    assert_equal 'a \\| b', Helper.markdown_escape("a | \n b")
  end

  private

  def mixed_log_lines
    [
      "#{REPO_ROOT}/WooCommerce/Classes/ViewRelated/A.swift:42:9: warning: initialization of immutable value 'x' was never used",
      "\e[33m#{REPO_ROOT}/Modules/Sources/Yosemite/B.swift:100: warning: colored warning\e[0m",
      '/Applications/Xcode.app/Toolchains/foo.swift:1:1: warning: external warning',
      'ld: warning: linker noise',
      'Compiling A.swift (no warning here)'
    ]
  end

  def count_report(log_lines)
    Dir.mktmpdir do |dir|
      log_file = File.join(dir, 'build.log')
      File.write(log_file, "#{log_lines.join("\n")}\n")
      return Helper.count_warnings(log_files: [log_file], repo_root: REPO_ROOT, source: log_file)
    end
  end

  def warning_fixture(path: 'WooCommerce/Classes/ViewRelated/Existing.swift', message: 'existing warning', line: 10)
    { 'area' => 'WooCommerce/Classes/ViewRelated', 'path' => path, 'line' => line, 'column' => 5, 'message' => message }
  end

  def report_fixture(count: :from_warnings, scope: Helper::OWNED_SCOPE, warnings: [warning_fixture], breakdown: nil)
    count = warnings ? warnings.length : 0 if count == :from_warnings
    report = {
      'count' => count,
      'scope' => scope,
      'baseline_commit' => 'abc123def4567890',
      'baseline_cache_source' => 'local-cache'
    }
    report['warnings'] = warnings if warnings
    report['breakdown'] = breakdown if breakdown
    report
  end

  def build_comment(current:, baseline:)
    Helper.build_comment(
      current: current,
      baseline: baseline,
      base_branch: 'trunk',
      build_url: 'https://buildkite.example/builds/1',
      repository_url: 'https://github.com/woocommerce/woocommerce-ios',
      report_path: 'build-warnings.json',
      baseline_report_path: 'base-build-warnings.json'
    )
  end
end
