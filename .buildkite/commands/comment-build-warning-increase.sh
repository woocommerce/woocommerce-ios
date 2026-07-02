#!/bin/bash -eu

set -o pipefail

REPORT_PATH="${1:-build-warnings.json}"
BASELINE_REPORT_PATH="${2:-base-build-warnings.json}"
CURRENT_LOG_PATH="${3:-fastlane/logs}"
BASE_BRANCH="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-trunk}"
COMMENT_ID="build-warning-count"
COMMANDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_pull_request() {
  [[ "${BUILDKITE_PULL_REQUEST:-false}" =~ ^[0-9]+$ ]]
}

download_artifact_path() {
  local artifact_path=$1
  set +e

  if [[ "$artifact_path" == *"*"* || "$artifact_path" == *"?"* || "$artifact_path" == *"["* ]] && command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact download "$artifact_path" .
  elif command -v download_artifact >/dev/null 2>&1; then
    download_artifact "$artifact_path"
  elif command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact download "$artifact_path" .
  else
    set -e
    return 1
  fi
  local download_status=$?
  set -e

  return "$download_status"
}

download_report() {
  local report_path=$1

  if [ -f "$report_path" ]; then
    return
  fi

  mkdir -p "$(dirname "$report_path")"

  local download_status
  if download_artifact_path "$report_path"; then
    download_status=0
  else
    download_status=$?
  fi

  if [ ! -f "$report_path" ] && [ -f "$(basename "$report_path")" ]; then
    mv "$(basename "$report_path")" "$report_path"
  fi

  [ "$download_status" -eq 0 ] && [ -f "$report_path" ]
}

ensure_current_report() {
  if [ -f "$REPORT_PATH" ]; then
    return
  fi

  if download_report "$REPORT_PATH"; then
    return
  fi

  if [ ! -e "$CURRENT_LOG_PATH" ]; then
    download_artifact_path "$CURRENT_LOG_PATH/*" || true
  fi

  if [ ! -e "$CURRENT_LOG_PATH" ]; then
    return 1
  fi

  if ! "$COMMANDS_DIR/count-build-warnings.sh" "$CURRENT_LOG_PATH" "$REPORT_PATH"; then
    return 1
  fi

  if command -v upload_artifact >/dev/null 2>&1; then
    upload_artifact "$REPORT_PATH" || true
  elif command -v buildkite-agent >/dev/null 2>&1; then
    buildkite-agent artifact upload "$REPORT_PATH" || true
  fi

  return 0
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

if ! ensure_current_report; then
  echo "No current build warning report or logs found at $REPORT_PATH / $CURRENT_LOG_PATH; skipping comparison."
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

if [ "$current_count" -le "$baseline_count" ]; then
  echo "Build warnings did not increase: $current_count current vs $baseline_count baseline."
  delete_existing_comment
  exit 0
fi

increase=$((current_count - baseline_count))
breakdown_table="$(
  ruby -rjson -e '
    current = JSON.parse(File.read(ARGV[0]))
    baseline = JSON.parse(File.read(ARGV[1]))

    current_counts = current.fetch("breakdown", []).to_h { |entry| [entry.fetch("area"), entry.fetch("count").to_i] }
    baseline_counts = baseline.fetch("breakdown", []).to_h { |entry| [entry.fetch("area"), entry.fetch("count").to_i] }
    rows = (current_counts.keys | baseline_counts.keys)
      .map { |area| [area, current_counts.fetch(area, 0), baseline_counts.fetch(area, 0)] }
      .map { |area, current_count, baseline_count| [area, current_count, baseline_count, current_count - baseline_count] }
      .select { |(_, _, _, delta)| delta.positive? }
      .sort_by { |area, _, _, delta| [-delta, area] }

    if rows.empty?
      puts "_No individual area increased; warning distribution changed._"
      exit
    end

    displayed_rows = rows.first(15)
    puts "| Area | Current | Baseline | Delta |"
    puts "|---|---:|---:|---:|"
    displayed_rows.each do |area, current_count, baseline_count, delta|
      puts "| `#{area}` | #{current_count} | #{baseline_count} | +#{delta} |"
    end
    remaining = rows.length - displayed_rows.length
    puts "\n_#{remaining} more area#{remaining == 1 ? "" : "s"} increased._" if remaining.positive?
  ' "$REPORT_PATH" "$BASELINE_REPORT_PATH"
)"
additional_warnings_table="$(
  ruby -rjson -e '
    current = JSON.parse(File.read(ARGV[0]))
    baseline = JSON.parse(File.read(ARGV[1]))

    current_warnings = current.fetch("warnings", [])
    baseline_warnings = baseline.fetch("warnings", [])

    if current_warnings.empty? || baseline_warnings.empty?
      puts "_Exact additional warning details are unavailable because one report does not include warning entries._"
      exit
    end

    signature = lambda { |warning| [warning.fetch("path", ""), warning.fetch("message", "")].join("\0") }
    baseline_counts = Hash.new(0)
    baseline_warnings.each { |warning| baseline_counts[signature.call(warning)] += 1 }

    additional = []
    current_warnings.each do |warning|
      warning_signature = signature.call(warning)
      if baseline_counts[warning_signature].positive?
        baseline_counts[warning_signature] -= 1
      else
        additional << warning
      end
    end

    if additional.empty?
      puts "_No exact additional warnings found; warning distribution changed._"
      exit
    end

    def markdown_escape(value)
      value.to_s.gsub("|", "\\\\|").gsub(/\s+/, " ").strip
    end

    displayed_warnings = additional.first(20)
    puts "| File | Warning |"
    puts "|---|---|"
    displayed_warnings.each do |warning|
      path = warning.fetch("path", "")
      line = warning["line"]
      location = line ? "#{path}:#{line}" : path
      puts "| `#{markdown_escape(location)}` | #{markdown_escape(warning.fetch("message", ""))} |"
    end
    remaining = additional.length - displayed_warnings.length
    puts "\n_#{remaining} more additional warning#{remaining == 1 ? "" : "s"}._" if remaining.positive?
  ' "$REPORT_PATH" "$BASELINE_REPORT_PATH"
)"
comment_body="$(cat <<EOF
## Build warnings increased

This PR has **$current_count** owned app/module build warnings, which is **+$increase** compared with **$baseline_count** on $baseline_label.

- Current build: $BUILDKITE_BUILD_URL
- Baseline report: \`$BASELINE_REPORT_PATH\`

Only warnings tied to owned repo paths under \`WooCommerce/\`, \`Modules/Sources/\`, and \`Modules/Tests/\` are counted.

$breakdown_table

### Additional Warnings

$additional_warnings_table

Please remove the new warnings before merging.
EOF
)"

if command -v comment_on_pr >/dev/null 2>&1; then
  comment_on_pr --id "$COMMENT_ID" "$comment_body"
else
  echo "$comment_body"
fi
