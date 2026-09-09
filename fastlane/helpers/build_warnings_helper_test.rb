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
    assert_includes body, "#{Helper.markdown_literal('WooCommerce/Classes/ViewRelated/New.swift:10')} | <code>new warning</code>"
    refute_includes body, 'Occurrences'
  end

  def test_traded_warnings_with_no_net_increase_still_post_a_comment
    current = report_fixture(warnings: [warning_fixture(path: 'WooCommerce/Classes/ViewRelated/New.swift', message: 'new warning')])
    baseline = report_fixture(warnings: [warning_fixture])
    result = build_comment(current: current, baseline: baseline)

    body = result.fetch(:comment)
    assert_includes body, 'net change **0**'
    assert_includes body, "#{Helper.markdown_literal('WooCommerce/Classes/ViewRelated/New.swift:10')} | <code>new warning</code>"
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
    assert_includes body, "| 2 | #{Helper.markdown_literal('WooCommerce/Classes/ViewRelated/New.swift:10')} | <code>new warning</code> |"
  end

  def test_first_warning_against_empty_baseline_includes_exact_details
    body = build_comment(current: report_fixture, baseline: report_fixture(warnings: [])).fetch(:comment)

    assert_includes body, 'This PR introduces **1 new build warning**'
    assert_includes body, "#{Helper.markdown_literal('WooCommerce/Classes/ViewRelated/Existing.swift:10')} | <code>existing warning</code>"
    refute_includes body, 'details are unavailable'
  end

  def test_two_empty_reports_skip
    result = build_comment(current: report_fixture(warnings: []), baseline: report_fixture(warnings: []))

    assert result.key?(:skip)
  end

  def test_missing_or_non_array_warning_entries_are_unavailable
    [nil, 'invalid', {}].each do |warnings|
      malformed_report = report_fixture(count: 1, warnings: warnings)
      current_result = build_comment(current: malformed_report, baseline: report_fixture)
      baseline_result = build_comment(current: report_fixture, baseline: malformed_report)

      assert_match(/missing a valid warning entries array/, current_result.fetch(:unavailable))
      assert_match(/missing a valid warning entries array/, baseline_result.fetch(:unavailable))
    end
  end

  def test_warning_count_mismatch_is_unavailable
    result = build_comment(current: report_fixture(count: 2), baseline: report_fixture)

    assert_match(/count does not match its warning entries/, result.fetch(:unavailable))
  end

  def test_scope_mismatch_is_unavailable
    current = report_fixture
    baseline = report_fixture(scope: 'another_scope')
    result = build_comment(current: current, baseline: baseline)

    assert_match(/does not match current scope/, result.fetch(:unavailable))
  end

  def test_missing_current_scope_is_unavailable
    result = build_comment(current: report_fixture(scope: nil), baseline: report_fixture)

    assert_match(/missing a scope/, result.fetch(:unavailable))
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
    assert_includes body, "| #{Helper.markdown_literal('WooCommerce/Classes/ViewRelated')} | 2 | 1 | +1 |"
    assert_includes body, 'Artifacts tab of the [CI build](https://buildkite.example/builds/1)'
    assert_includes body, '- Baseline source: `local-cache`'
    assert_includes body, 'renaming or moving a file can report its pre-existing warnings as new'
    assert_includes body, 'Please consider removing the new warnings before merging.'
  end

  def test_markdown_literal_encodes_punctuation_to_keep_it_out_of_markdown_parsing
    text = "` @review-team [link](https://example.com) </details> | \n warning"

    assert_equal '<code>&#96; &#64;review&#45;team &#91;link&#93;&#40;https&#58;&#47;&#47;example&#46;com&#41; ' \
                 '&#60;&#47;details&#62; &#124; warning</code>', Helper.markdown_literal(text)
  end

  def test_markdown_literal_preserves_backslash_runs_before_pipes_without_table_delimiters
    (0..3).each do |count|
      assert_equal "<code>#{'&#92;' * count}&#124;</code>", Helper.markdown_literal(('\\' * count) + '|')
    end
  end

  def test_warning_paths_messages_and_areas_are_rendered_as_literal_code
    text = '`code`` @review-team [link](https://example.com) </details> | warning'
    warning = warning_fixture(path: "WooCommerce/#{text}.swift", message: text)
    current = report_fixture(warnings: [warning], breakdown: [{ 'area' => text, 'count' => 1 }])
    body = build_comment(current: current, baseline: report_fixture(warnings: [])).fetch(:comment)

    assert_includes body, Helper.markdown_literal("WooCommerce/#{text}.swift:10")
    assert_includes body, "| #{Helper.markdown_literal(text)} |"
    assert_includes body, "| #{Helper.markdown_literal(text)} | 1 | 0 | +1 |"
  end

  def test_warning_and_area_tables_limit_rows_and_link_full_reports
    warnings = 60.times.map { |index| warning_fixture(path: "WooCommerce/File#{index}.swift", message: "warning #{index}") }
    breakdown = 60.times.map { |index| { 'area' => "WooCommerce/Area#{index}", 'count' => 1 } }
    current = report_fixture(warnings: warnings, breakdown: breakdown)
    body = build_comment(current: current, baseline: report_fixture(warnings: [])).fetch(:comment)

    assert_equal 2, body.scan('Showing 50 of 60 rows.').length
    assert_includes body, 'Full JSON reports are in the Artifacts tab of the [CI build](https://buildkite.example/builds/1).'
    assert_operator body.bytesize, :<=, Helper::MAX_COMMENT_BYTES
  end

  def test_warning_and_area_tables_limit_bytes_for_large_multibyte_fields
    warnings = 600.times.map { |index| warning_fixture(path: "WooCommerce/#{'é' * 500}#{index}.swift", message: '界' * 500) }
    breakdown = 600.times.map { |index| { 'area' => "WooCommerce/#{'界' * 500}#{index}", 'count' => 1 } }
    current = report_fixture(warnings: warnings, breakdown: breakdown)
    body = build_comment(current: current, baseline: report_fixture(warnings: [])).fetch(:comment)

    assert_match(/Showing \d+ of 600 rows/, body)
    assert_operator body.bytesize, :<=, Helper::MAX_COMMENT_BYTES
    assert body.valid_encoding?
    assert_equal 3, body.scan('</details>').length
  end

  def test_an_oversized_warning_or_area_links_full_reports_without_truncating_markup
    warning = warning_fixture(path: "WooCommerce/#{'`' * Helper::MAX_COMMENT_BYTES}.swift", message: '界' * Helper::MAX_COMMENT_BYTES)
    current = report_fixture(warnings: [warning], breakdown: [{ 'area' => '界' * Helper::MAX_COMMENT_BYTES, 'count' => 1 }])
    body = build_comment(current: current, baseline: report_fixture(warnings: [])).fetch(:comment)

    assert_equal 2, body.scan('Showing 0 of 1 rows.').length
    assert_operator body.bytesize, :<=, Helper::MAX_COMMENT_BYTES
    assert_equal 3, body.scan('</details>').length
  end

  def test_oversized_summary_falls_back_to_a_short_comment_with_full_report_link
    baseline = report_fixture(warnings: []).merge('baseline_cache_source' => 'x' * Helper::MAX_COMMENT_BYTES)
    body = build_comment(current: report_fixture, baseline: baseline).fetch(:comment)

    assert_includes body, 'The warning summary exceeds the comment size limit.'
    assert_includes body, 'Artifacts tab of the [CI build](https://buildkite.example/builds/1).'
    assert_operator body.bytesize, :<=, Helper::MAX_COMMENT_BYTES
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
