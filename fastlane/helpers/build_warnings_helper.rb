# frozen_string_literal: true

require 'json'

# Pure-Ruby logic for the CI build warning guard.
#
# Two responsibilities, both free of Fastlane / network dependencies so they
# can be exercised by unit tests:
# - Parse Xcode build logs into a warning report scoped to owned repo paths.
# - Compare a PR report against the PR base baseline and render the PR
#   comment markdown.
#
# The `.buildkite/commands/*.rb` wrappers and bash steps only orchestrate
# artifact downloads and PR commenting around this module.
module BuildWarningsHelper # rubocop:disable Metrics/ModuleLength
  OWNED_SCOPE = 'owned_app_and_modules'

  ANSI_ESCAPE = /\e\[[0-9;]*[A-Za-z]/
  WARNING_LINE_MARKER = /(^|[^[:alnum:]_])warning:/
  WARNING_PATTERN = /\A(?<location>.*?): warning: (?<message>.*)\z/

  module_function

  # --- Report generation ------------------------------------------------------

  # @param log_path [String] a build log file, or a directory of `.log`/`.txt` files
  # @return [Array<String>, nil] log file paths, or nil when the path does not exist
  def collect_log_files(log_path)
    if File.file?(log_path)
      [log_path]
    elsif File.directory?(log_path)
      Dir.glob(File.join(log_path, '**', '*.{log,txt}')).select { |file| File.file?(file) }.sort
    end
  end

  # Strips a leading `./` or the repo root prefix; returns nil for absolute
  # paths outside the repo (dependencies, DerivedData, toolchain files).
  def normalize_repo_path(path, repo_root)
    path = path.sub(%r{\A\./}, '')
    return path.delete_prefix("#{repo_root}/") if path.start_with?("#{repo_root}/")
    return nil if path.start_with?('/')

    path
  end

  APP_AREA_PREFIXES = [
    'WooCommerce/StoreWidgets',
    'WooCommerce/WordPressAuthenticator',
    'WooCommerce/Woo Watch App',
    'WooCommerce/WooCommerceTests'
  ].freeze

  # Buckets an app-target path into a reporting area (e.g. `WooCommerce/Classes/ViewRelated`).
  def app_area(path)
    if (match = path.match(%r{\AWooCommerce/Classes/(.+)}))
      classes_segments = match[1].split('/')
      return classes_segments.length > 1 ? "WooCommerce/Classes/#{classes_segments[0]}" : 'WooCommerce/Classes'
    end

    prefix = APP_AREA_PREFIXES.find { |candidate| path.start_with?(candidate) }
    return prefix if prefix

    segments = path.split('/')
    segments.length > 1 ? "WooCommerce/#{segments[1]}" : 'WooCommerce'
  end

  # @return [String, nil] the owned area for a repo-relative path, or nil when not owned
  def owned_warning_area(path)
    return app_area(path) if path.start_with?('WooCommerce/') && !path.start_with?('WooCommerce/WooCommerce.xcodeproj/')

    match = path.match(%r{\AModules/(Sources|Tests)/([^/]+)})
    return "Modules/#{match[1]}/#{match[2]}" if match

    nil
  end

  # Splits a `path[:line[:column]]` warning location.
  #
  # @return [Array(String, Integer?, Integer?)] path, line, column
  def parse_warning_location(location)
    if (match = location.match(/\A(?<path>.*):(?<line>\d+):(?<column>\d+)\z/))
      [match[:path], match[:line].to_i, match[:column].to_i]
    elsif (match = location.match(/\A(?<path>.*):(?<line>\d+)\z/))
      [match[:path], match[:line].to_i, nil]
    else
      [location.sub(%r{:[^:/]+\z}, ''), nil, nil]
    end
  end

  # @return [Hash, nil] a warning entry for an owned repo path, or nil
  def parse_warning_line(line, repo_root)
    match = line.match(WARNING_PATTERN)
    return nil unless match

    path, line_number, column = parse_warning_location(match[:location])
    repo_path = normalize_repo_path(path, repo_root)
    return nil unless repo_path

    area = owned_warning_area(repo_path)
    return nil unless area

    { area: area, path: repo_path, line: line_number, column: column, message: match[:message].strip }
  end

  # Parses build logs into a warning report hash (the JSON report shape).
  #
  # @param log_files [Array<String>] build log paths
  # @param repo_root [String] checkout root the log's absolute paths are rooted in
  # @param source [String] recorded in the report as the log origin
  def count_warnings(log_files:, repo_root:, source:, scope: OWNED_SCOPE)
    repo_root = File.expand_path(repo_root)
    total_warning_lines = 0
    warnings = []

    log_files.each do |log_file|
      File.foreach(log_file) do |raw_line|
        line = raw_line.gsub(ANSI_ESCAPE, '').chomp
        next unless line.match?(WARNING_LINE_MARKER)

        total_warning_lines += 1
        warning = parse_warning_line(line, repo_root)
        warnings << warning if warning
      end
    end

    build_report(warnings: warnings, total_warning_lines: total_warning_lines, scope: scope, source: source)
  end

  def build_report(warnings:, total_warning_lines:, scope:, source:)
    {
      count: warnings.length,
      scope: scope,
      source: source,
      generated_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
      total_warning_lines: total_warning_lines,
      excluded_warning_lines: total_warning_lines - warnings.length,
      breakdown: sorted_breakdown(warnings),
      warnings: warnings.sort_by { |warning| [warning[:area], warning[:path], warning[:line] || 0, warning[:column] || 0, warning[:message]] }
    }
  end

  def sorted_breakdown(warnings)
    warnings
      .each_with_object(Hash.new(0)) { |warning, counts| counts[warning[:area]] += 1 }
      .sort_by { |area, count| [-count, area] }
      .map { |area, count| { area: area, count: count } }
  end

  # @return [Array<String>] human-readable summary lines for the build log
  def report_summary_lines(report)
    lines = ["Build warning count (#{report[:scope]}): #{report[:count]}", 'Breakdown:']
    report[:breakdown].each { |entry| lines << "  #{entry[:count].to_s.rjust(4)}  #{entry[:area]}" }
    lines
  end

  # --- Comparison and PR comment ----------------------------------------------

  # Compares a current report against the baseline and renders the PR comment.
  #
  # @param current [Hash] parsed current report JSON (string keys)
  # @param baseline [Hash] parsed baseline report JSON (string keys)
  # @return [Hash] `{ comment: String }` when a comment should be posted, or
  #   `{ skip: String }` with the reason when no comment is warranted
  # @raise [ArgumentError] when either report has a malformed count
  def build_comment(current:, baseline:, base_branch:, build_url:, repository_url:, report_path:, baseline_report_path:) # rubocop:disable Metrics/ParameterLists
    current_count = validate_count(current['count'], "Invalid current build warning count in #{report_path}")
    skip = scope_skip_reason(current: current, baseline: baseline)
    return { skip: skip } if skip

    baseline_count = validate_count(baseline['count'], 'Invalid baseline build warning count')

    comparison = compare_warnings(current: current, baseline: baseline)
    count_delta = current_count - baseline_count
    if comparison[:additional].empty? && count_delta <= 0
      return { skip: "Build warnings did not increase and no exact additional warnings were found: #{current_count} current vs #{baseline_count} baseline." }
    end

    { comment: render_comment(current_count: current_count, baseline_count: baseline_count, count_delta: count_delta, comparison: comparison,
                              baseline: baseline, base_branch: base_branch, build_url: build_url, repository_url: repository_url,
                              report_path: report_path, baseline_report_path: baseline_report_path) }
  end

  def validate_count(count, error_prefix)
    return count if count.is_a?(Integer) && count >= 0

    raise ArgumentError, "#{error_prefix}: #{count.inspect}"
  end

  def scope_skip_reason(current:, baseline:)
    current_scope = current['scope'].to_s
    return 'Current build warning report is missing a scope; skipping comparison.' if current_scope.empty?

    baseline_scope = baseline['scope'].to_s
    return "Baseline warning scope '#{baseline_scope}' does not match current scope '#{current_scope}'; skipping comparison." if baseline_scope != current_scope

    nil
  end

  # @return [Hash] `:rows` (area deltas), `:additional` (exact new warning
  #   entries), `:unique_additional` (grouped by file/line/column/message),
  #   and `:details_available`
  def compare_warnings(current:, baseline:)
    current_warnings = current.fetch('warnings', [])
    baseline_warnings = baseline.fetch('warnings', [])
    details_available = !(current_warnings.empty? || baseline_warnings.empty?)
    additional = details_available ? additional_warnings(current_warnings: current_warnings, baseline_warnings: baseline_warnings) : []

    {
      rows: area_rows(current: current, baseline: baseline),
      additional: additional,
      unique_additional: group_unique_warnings(additional),
      details_available: details_available
    }
  end

  def breakdown_counts(report)
    report.fetch('breakdown', []).to_h { |entry| [entry.fetch('area'), entry.fetch('count').to_i] }
  end

  def area_rows(current:, baseline:)
    current_counts = breakdown_counts(current)
    baseline_counts = breakdown_counts(baseline)

    rows = (current_counts.keys | baseline_counts.keys).map do |area|
      current_count = current_counts.fetch(area, 0)
      baseline_count = baseline_counts.fetch(area, 0)
      [area, current_count, baseline_count, current_count - baseline_count]
    end
    rows.select { |(_, _, _, delta)| delta.positive? }.sort_by { |area, _, _, delta| [-delta, area] }
  end

  # Multiset difference keyed by file path and message, so line shifts alone
  # are not flagged while extra occurrences of an existing warning are.
  def additional_warnings(current_warnings:, baseline_warnings:)
    signature = ->(warning) { [warning.fetch('path', ''), warning.fetch('message', '')].join("\0") }
    baseline_warning_counts = Hash.new(0)
    baseline_warnings.each { |warning| baseline_warning_counts[signature.call(warning)] += 1 }

    current_warnings.reject do |warning|
      warning_signature = signature.call(warning)
      matched = baseline_warning_counts[warning_signature].positive?
      baseline_warning_counts[warning_signature] -= 1 if matched
      matched
    end
  end

  def unique_warning_sort_key(warning)
    [warning.fetch('area', ''), warning.fetch('path', ''), warning['line'] || 0, warning['column'] || 0, warning.fetch('message', '')]
  end

  def group_unique_warnings(additional)
    additional
      .group_by { |warning| [warning.fetch('path', ''), warning['line'], warning['column'], warning.fetch('message', '')] }
      .values
      .map { |warnings| { warning: warnings.first, count: warnings.length } }
      .sort_by { |entry| unique_warning_sort_key(entry[:warning]) }
  end

  def markdown_escape(value)
    value.to_s.gsub('|', '\\|').gsub(/\s+/, ' ').strip
  end

  def pluralize(count, singular, plural = nil)
    count == 1 ? singular : (plural || "#{singular}s")
  end

  def area_breakdown_markdown(rows)
    return '_No individual area has a higher warning count; exact warning identities changed._' if rows.empty?

    lines = ['<details>', "<summary>Area breakdown: #{rows.length} #{pluralize(rows.length, 'area')} with higher warning counts</summary>", '']
    lines << '| Area | Current | Baseline | Count change |'
    lines << '|---|---:|---:|---:|'
    rows.each do |area, current_count, baseline_count, delta|
      lines << "| `#{markdown_escape(area)}` | #{current_count} | #{baseline_count} | +#{delta} |"
    end
    lines.push('', '</details>').join("\n")
  end

  def additional_warnings_markdown(comparison)
    return '_Exact additional warning details are unavailable because one report does not include warning entries._' unless comparison[:details_available]

    unique_additional = comparison[:unique_additional]
    return '_No exact additional warnings found; warning distribution changed._' if unique_additional.empty?

    has_duplicates = comparison[:additional].length != unique_additional.length
    lines = ['<details>']
    lines.concat(additional_warnings_table_header(unique_count: unique_additional.length, entry_count: comparison[:additional].length,
                                                  has_duplicates: has_duplicates))
    unique_additional.each { |entry| lines << additional_warning_row(entry, has_duplicates: has_duplicates) }
    lines.push('', '</details>').join("\n")
  end

  def additional_warnings_table_header(unique_count:, entry_count:, has_duplicates:)
    if has_duplicates
      ["<summary>New warnings: #{unique_count} (#{entry_count} entries in the build log)</summary>", '',
       'The same warning can appear multiple times in the build log (e.g. a file compiled into several targets); ' \
       'occurrences are grouped by file, line, and message.', '',
       '| Occurrences | File | Warning |', '|---:|---|---|']
    else
      ["<summary>New warnings: #{unique_count}</summary>", '', '| File | Warning |', '|---|---|']
    end
  end

  def additional_warning_row(entry, has_duplicates:)
    warning = entry[:warning]
    path = warning.fetch('path', '')
    location = warning['line'] ? "#{path}:#{warning['line']}" : path
    row = "| `#{markdown_escape(location)}` | #{markdown_escape(warning.fetch('message', ''))} |"
    row = "| #{entry[:count]} #{row}" if has_duplicates
    row
  end

  def baseline_label(baseline:, base_branch:, repository_url:)
    baseline_commit = baseline['baseline_commit'].to_s
    return 'the PR base build warning baseline' if baseline_commit.empty?

    repository_url = repository_url.delete_suffix('.git')
    repository_url = "https://github.com/#{repository_url.delete_prefix('git@github.com:')}" if repository_url.start_with?('git@github.com:')
    "PR base `#{base_branch}` at [#{baseline_commit[0, 12]}](#{repository_url}/commit/#{baseline_commit})"
  end

  def headline(current_count:, baseline_count:, unique_additional_count:, baseline_label:)
    if unique_additional_count.positive?
      label = "#{unique_additional_count} new build #{pluralize(unique_additional_count, 'warning')}"
      "This PR introduces **#{label}** not present on #{baseline_label}."
    else
      "This PR raises the build warning count to **#{current_count}**, up from **#{baseline_count}** on #{baseline_label}."
    end
  end

  def details_section(current_count:, baseline_count:, count_delta:, additional_count:, baseline:, base_branch:, build_url:, report_path:, baseline_report_path:) # rubocop:disable Metrics/ParameterLists
    count_delta_label = count_delta.positive? ? "+#{count_delta}" : count_delta.to_s
    baseline_cache_source = baseline['baseline_cache_source'].to_s
    ['<details>', '<summary>Details and caveats</summary>', '',
     "- Full JSON reports are in the Artifacts tab of the [CI build](#{build_url}): `#{report_path}` for this PR (uploaded by the Build step) " \
     "and `#{baseline_report_path}` for the base branch (uploaded by the Build Warning Baseline step).",
     baseline_cache_source.empty? ? '' : "- Baseline source: `#{baseline_cache_source}`",
     "- Warning counts: **#{current_count}** on this PR vs **#{baseline_count}** on the base — net change **#{count_delta_label}**, " \
     "with #{additional_count} exact additional warning #{pluralize(additional_count, 'entry', 'entries')}.",
     '- Only warnings in files under `WooCommerce/`, `Modules/Sources/`, and `Modules/Tests/` are counted; ' \
     'warnings from dependencies and generated code are ignored.',
     '- Warnings are matched by file path and message: renaming or moving a file can report its pre-existing warnings as new, ' \
     'while line-number shifts alone are not flagged.',
     "- The baseline is built from the merge base of this PR and `#{base_branch}`; rebasing refreshes it.",
     '', '</details>'].join("\n")
  end

  def render_comment(current_count:, baseline_count:, count_delta:, comparison:, baseline:, base_branch:, build_url:, repository_url:, report_path:, baseline_report_path:) # rubocop:disable Metrics/ParameterLists
    label = baseline_label(baseline: baseline, base_branch: base_branch, repository_url: repository_url)
    ['## New build warnings detected', '',
     headline(current_count: current_count, baseline_count: baseline_count,
              unique_additional_count: comparison[:unique_additional].length, baseline_label: label), '',
     additional_warnings_markdown(comparison), '',
     area_breakdown_markdown(comparison[:rows]), '',
     details_section(current_count: current_count, baseline_count: baseline_count, count_delta: count_delta,
                     additional_count: comparison[:additional].length, baseline: baseline, base_branch: base_branch,
                     build_url: build_url, report_path: report_path, baseline_report_path: baseline_report_path), '',
     'Please consider removing the new warnings before merging.'].join("\n")
  end
end
