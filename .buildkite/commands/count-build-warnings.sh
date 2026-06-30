#!/bin/bash -eu

set -o pipefail

LOG_PATH="${1:-fastlane/logs}"
OUTPUT_PATH="${2:-build/build-warnings.json}"
SCOPE="owned_app_and_modules"
REPO_ROOT="${BUILDKITE_BUILD_CHECKOUT_PATH:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

log_files_list="$(mktemp)"
trap 'rm -f "$log_files_list"' EXIT

if [ -f "$LOG_PATH" ]; then
  printf '%s\n' "$LOG_PATH" > "$log_files_list"
elif [ -d "$LOG_PATH" ]; then
  find "$LOG_PATH" -type f \( -name '*.log' -o -name '*.txt' \) | sort > "$log_files_list"
else
  echo "Build log path not found: $LOG_PATH" >&2
  exit 1
fi

if [ ! -s "$log_files_list" ]; then
  echo "No build logs found under: $LOG_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

export LOG_FILES_LIST="$log_files_list"
export LOG_PATH
export OUTPUT_PATH
export REPO_ROOT
export SCOPE

ruby -rjson <<'RUBY'
repo_root = File.expand_path(ENV.fetch('REPO_ROOT'))
log_path = ENV.fetch('LOG_PATH')
output_path = ENV.fetch('OUTPUT_PATH')
scope = ENV.fetch('SCOPE')
log_files = File.readlines(ENV.fetch('LOG_FILES_LIST'), chomp: true)

def normalize_repo_path(path, repo_root)
  path = path.sub(%r{\A\./}, '')
  return path.delete_prefix("#{repo_root}/") if path.start_with?("#{repo_root}/")
  return nil if path.start_with?('/')

  path
end

def app_area(path)
  segments = path.split('/')

  case path
  when %r{\AWooCommerce/Classes/(.+)}
    classes_path = Regexp.last_match(1)
    classes_segments = classes_path.split('/')
    classes_segments.length > 1 ? "WooCommerce/Classes/#{classes_segments[0]}" : 'WooCommerce/Classes'
  when %r{\AWooCommerce/StoreWidgets}
    'WooCommerce/StoreWidgets'
  when %r{\AWooCommerce/WordPressAuthenticator}
    'WooCommerce/WordPressAuthenticator'
  when %r{\AWooCommerce/Woo Watch App}
    'WooCommerce/Woo Watch App'
  when %r{\AWooCommerce/WooCommerceTests}
    'WooCommerce/WooCommerceTests'
  else
    segments.length > 1 ? "WooCommerce/#{segments[1]}" : 'WooCommerce'
  end
end

def owned_warning_area(path)
  return app_area(path) if path.start_with?('WooCommerce/') && !path.start_with?('WooCommerce/WooCommerce.xcodeproj/')

  match = path.match(%r{\AModules/(Sources|Tests)/([^/]+)})
  return "Modules/#{match[1]}/#{match[2]}" if match

  nil
end

total_warning_lines = 0
owned_warning_count = 0
breakdown = Hash.new(0)

log_files.each do |log_file|
  File.foreach(log_file) do |line|
    line = line.gsub(/\e\[[0-9;]*[A-Za-z]/, '')
    next unless line.match?(/(^|[^[:alnum:]_])warning:/)

    total_warning_lines += 1
    match = line.match(/\A(?<location>.*?): warning:/)
    next unless match

    warning_path = match[:location]
      .sub(/:\d+(?::\d+)?\z/, '')
      .sub(/:[^:\/]+\z/, '')

    repo_path = normalize_repo_path(warning_path, repo_root)
    next unless repo_path

    area = owned_warning_area(repo_path)
    next unless area

    owned_warning_count += 1
    breakdown[area] += 1
  end
end

report = {
  count: owned_warning_count,
  scope: scope,
  source: log_path,
  generated_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
  total_warning_lines: total_warning_lines,
  excluded_warning_lines: total_warning_lines - owned_warning_count,
  breakdown: breakdown.sort_by { |area, count| [-count, area] }.map { |area, count| { area: area, count: count } }
}

File.write(output_path, "#{JSON.pretty_generate(report)}\n")

puts "Build warning count (#{scope}): #{owned_warning_count}"
puts 'Breakdown:'
report[:breakdown].each do |entry|
  puts "  #{entry[:count].to_s.rjust(4)}  #{entry[:area]}"
end
RUBY

echo "Wrote build warning report to $OUTPUT_PATH"
