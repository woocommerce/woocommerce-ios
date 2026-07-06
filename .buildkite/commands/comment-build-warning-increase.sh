#!/bin/bash -eu

set -o pipefail

REPORT_PATH="${1:-build-warnings.json}"
BASELINE_REPORT_PATH="${2:-base-build-warnings.json}"
BASE_BRANCH="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-trunk}"
COMMENT_ID="build-warning-count"

is_pull_request() {
  [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]
}

download_artifact_path() {
  local artifact_path=$1

  if command -v download_artifact >/dev/null 2>&1; then
    download_artifact "$artifact_path"
  elif command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact download "$artifact_path" .
  else
    return 1
  fi
}

download_report() {
  local report_path=$1

  # Reused agent checkouts can contain reports from previous builds; never
  # trust a pre-existing file, always fetch the artifact from this build.
  rm -f "$report_path"
  mkdir -p "$(dirname "$report_path")"

  download_artifact_path "$report_path" || true

  if [ ! -f "$report_path" ] && [ -f "$(basename "$report_path")" ]; then
    mv "$(basename "$report_path")" "$report_path"
  fi

  [ -f "$report_path" ]
}

delete_existing_comment() {
  if command -v comment_on_pr >/dev/null 2>&1; then
    comment_on_pr --id "$COMMENT_ID" --if-exist delete
  fi
}

if ! is_pull_request; then
  echo "Not a pull request build; skipping build warning comparison."
  exit 0
fi

if ! download_report "$REPORT_PATH"; then
  echo "No current build warning report artifact found at $REPORT_PATH; skipping comparison."
  delete_existing_comment
  exit 0
fi

if ! download_report "$BASELINE_REPORT_PATH"; then
  echo "No baseline build warning report found at $BASELINE_REPORT_PATH; skipping comparison."
  delete_existing_comment
  exit 0
fi

current_count="$(jq -r '.count' "$REPORT_PATH")"
current_scope="$(jq -r '.scope // empty' "$REPORT_PATH")"

if ! [[ "$current_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid current build warning count in $REPORT_PATH: $current_count" >&2
  exit 1
fi

if [ -z "$current_scope" ]; then
  echo "Current build warning report is missing a scope; skipping comparison."
  delete_existing_comment
  exit 0
fi

baseline_scope="$(jq -r '.scope // empty' "$BASELINE_REPORT_PATH")"
if [ "$baseline_scope" != "$current_scope" ]; then
  echo "Baseline warning scope '$baseline_scope' does not match current scope '$current_scope'; skipping comparison."
  delete_existing_comment
  exit 0
fi

baseline_count="$(jq -r '.count' "$BASELINE_REPORT_PATH")"
if ! [[ "$baseline_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid baseline build warning count: $baseline_count" >&2
  exit 1
fi

baseline_cache_source="$(jq -r '.baseline_cache_source // empty' "$BASELINE_REPORT_PATH")"
baseline_cache_source_line=""
if [ -n "$baseline_cache_source" ]; then
  baseline_cache_source_line="- Baseline source: \`$baseline_cache_source\`"
fi

baseline_commit="$(jq -r '.baseline_commit // empty' "$BASELINE_REPORT_PATH")"
baseline_short_commit="${baseline_commit:0:12}"
if [ -n "$baseline_short_commit" ]; then
  repository_url="${BUILDKITE_REPO:-https://github.com/woocommerce/woocommerce-ios}"
  repository_url="${repository_url%.git}"
  if [[ "$repository_url" == git@github.com:* ]]; then
    repository_url="https://github.com/${repository_url#git@github.com:}"
  fi
  baseline_label="PR base \`$BASE_BRANCH\` at [$baseline_short_commit]($repository_url/commit/$baseline_commit)"
else
  baseline_label="the PR base build warning baseline"
fi

comparison_report="$(
  ruby -rjson -e '
    current = JSON.parse(File.read(ARGV[0]))
    baseline = JSON.parse(File.read(ARGV[1]))

    def pluralize(count, singular, plural = nil)
      count == 1 ? singular : (plural || "#{singular}s")
    end

    def markdown_escape(value)
      value.to_s.gsub("|", "\\|").gsub(/\s+/, " ").strip
    end

    current_counts = current.fetch("breakdown", []).to_h { |entry| [entry.fetch("area"), entry.fetch("count").to_i] }
    baseline_counts = baseline.fetch("breakdown", []).to_h { |entry| [entry.fetch("area"), entry.fetch("count").to_i] }
    rows = (current_counts.keys | baseline_counts.keys)
      .map { |area| [area, current_counts.fetch(area, 0), baseline_counts.fetch(area, 0)] }
      .map { |area, current_count, baseline_count| [area, current_count, baseline_count, current_count - baseline_count] }
      .select { |(_, _, _, delta)| delta.positive? }
      .sort_by { |area, _, _, delta| [-delta, area] }

    if rows.empty?
      area_breakdown = "_No individual area has a higher warning count; exact warning identities changed._"
    else
      area_lines = []
      area_lines << "<details>"
      area_lines << "<summary>Area breakdown: #{rows.length} #{pluralize(rows.length, "area")} with higher warning counts</summary>"
      area_lines << ""
      area_lines << "| Area | Current | Baseline | Count change |"
      area_lines << "|---|---:|---:|---:|"
      rows.each do |area, current_count, baseline_count, delta|
        area_lines << "| `#{markdown_escape(area)}` | #{current_count} | #{baseline_count} | +#{delta} |"
      end
      area_lines << ""
      area_lines << "</details>"
      area_breakdown = area_lines.join("\n")
    end

    current_warnings = current.fetch("warnings", [])
    baseline_warnings = baseline.fetch("warnings", [])

    if current_warnings.empty? || baseline_warnings.empty?
      additional = []
      unique_additional = []
      additional_warnings_table = "_Exact additional warning details are unavailable because one report does not include warning entries._"
    else
      signature = lambda { |warning| [warning.fetch("path", ""), warning.fetch("message", "")].join("\0") }
      baseline_warning_counts = Hash.new(0)
      baseline_warnings.each { |warning| baseline_warning_counts[signature.call(warning)] += 1 }

      additional = []
      current_warnings.each do |warning|
        warning_signature = signature.call(warning)
        if baseline_warning_counts[warning_signature].positive?
          baseline_warning_counts[warning_signature] -= 1
        else
          additional << warning
        end
      end

      unique_warning_counts = {}
      additional.each do |warning|
        unique_signature = [
          warning.fetch("path", ""),
          warning["line"],
          warning["column"],
          warning.fetch("message", "")
        ]
        unique_warning_counts[unique_signature] ||= { warning: warning, count: 0 }
        unique_warning_counts[unique_signature][:count] += 1
      end

      unique_additional = unique_warning_counts.values.sort_by do |entry|
        warning = entry[:warning]
        [
          warning.fetch("area", ""),
          warning.fetch("path", ""),
          warning["line"] || 0,
          warning["column"] || 0,
          warning.fetch("message", "")
        ]
      end

      if unique_additional.empty?
        additional_warnings_table = "_No exact additional warnings found; warning distribution changed._"
      else
        warning_lines = []
        warning_lines << "<details>"
        warning_lines << "<summary>New warnings: #{unique_additional.length} (#{additional.length} log #{pluralize(additional.length, "entry", "entries")})</summary>"
        warning_lines << ""
        warning_lines << "Duplicate warning entries from repeated build invocations are grouped by file, line, and message."
        warning_lines << ""
        warning_lines << "| Occurrences | File | Warning |"
        warning_lines << "|---:|---|---|"
        unique_additional.each do |entry|
          warning = entry[:warning]
          path = warning.fetch("path", "")
          line = warning["line"]
          location = line ? "#{path}:#{line}" : path
          warning_lines << "| #{entry[:count]} | `#{markdown_escape(location)}` | #{markdown_escape(warning.fetch("message", ""))} |"
        end
        warning_lines << ""
        warning_lines << "</details>"
        additional_warnings_table = warning_lines.join("\n")
      end
    end

    puts "INCREASED_AREAS_COUNT=#{rows.length}"
    puts "ADDITIONAL_WARNING_ENTRIES=#{additional.length}"
    puts "UNIQUE_ADDITIONAL_WARNINGS=#{unique_additional.length}"
    puts "__AREA_BREAKDOWN__"
    puts area_breakdown
    puts "__ADDITIONAL_WARNINGS__"
    puts additional_warnings_table
  ' "$REPORT_PATH" "$BASELINE_REPORT_PATH"
)"
increased_areas_count="$(printf '%s\n' "$comparison_report" | sed -n 's/^INCREASED_AREAS_COUNT=//p')"
additional_warnings_count="$(printf '%s\n' "$comparison_report" | sed -n 's/^ADDITIONAL_WARNING_ENTRIES=//p')"
unique_additional_warnings_count="$(printf '%s\n' "$comparison_report" | sed -n 's/^UNIQUE_ADDITIONAL_WARNINGS=//p')"
area_breakdown_table="$(printf '%s\n' "$comparison_report" | sed -n '/^__AREA_BREAKDOWN__$/,/^__ADDITIONAL_WARNINGS__$/p' | sed '1d;$d')"
additional_warnings_table="$(printf '%s\n' "$comparison_report" | sed -n '/^__ADDITIONAL_WARNINGS__$/,$p' | sed '1d')"

if ! [[ "$additional_warnings_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid additional warning count: $additional_warnings_count" >&2
  exit 1
fi
if ! [[ "$unique_additional_warnings_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid unique additional warning count: $unique_additional_warnings_count" >&2
  exit 1
fi
if ! [[ "$increased_areas_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid increased areas count: $increased_areas_count" >&2
  exit 1
fi

count_delta=$((current_count - baseline_count))
if [ "$additional_warnings_count" -eq 0 ] && [ "$count_delta" -le 0 ]; then
  echo "Build warnings did not increase and no exact additional warnings were found: $current_count current vs $baseline_count baseline."
  delete_existing_comment
  exit 0
fi

if [ "$count_delta" -gt 0 ]; then
  count_delta_label="+$count_delta"
else
  count_delta_label="$count_delta"
fi

new_warning_label="$unique_additional_warnings_count new build warning"
if [ "$unique_additional_warnings_count" -ne 1 ]; then
  new_warning_label="${new_warning_label}s"
fi

if [ "$unique_additional_warnings_count" -gt 0 ]; then
  headline="This PR introduces **$new_warning_label** not present on $baseline_label."
else
  headline="This PR raises the build warning count to **$current_count**, up from **$baseline_count** on $baseline_label."
fi

additional_entry_word="entries"
if [ "$additional_warnings_count" -eq 1 ]; then
  additional_entry_word="entry"
fi

comment_body="$(cat <<EOF
## New build warnings detected

$headline

$additional_warnings_table

$area_breakdown_table

<details>
<summary>Details and caveats</summary>

- Full JSON reports are in the Artifacts tab of the [CI build]($BUILDKITE_BUILD_URL): \`$REPORT_PATH\` for this PR (uploaded by the Build step) and \`$BASELINE_REPORT_PATH\` for the base branch (uploaded by the Build Warning Baseline step).
$baseline_cache_source_line
- Warning counts: **$current_count** on this PR vs **$baseline_count** on the base — net change **$count_delta_label**, with $additional_warnings_count exact additional warning $additional_entry_word.
- Only warnings in files under \`WooCommerce/\`, \`Modules/Sources/\`, and \`Modules/Tests/\` are counted; warnings from dependencies and generated code are ignored.
- Warnings are matched by file path and message: renaming or moving a file can report its pre-existing warnings as new, while line-number shifts alone are not flagged.
- The baseline is built from the merge base of this PR and \`$BASE_BRANCH\`; rebasing refreshes it.

</details>

Please consider removing the new warnings before merging.
EOF
)"

if command -v comment_on_pr >/dev/null 2>&1; then
  comment_on_pr --id "$COMMENT_ID" "$comment_body"
else
  echo "$comment_body"
fi
