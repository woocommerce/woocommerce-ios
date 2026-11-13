#!/usr/bin/env ruby
# frozen_string_literal: true

# Parses Xcode build logs into a JSON build warning report scoped to owned
# repo paths. Logic lives in BuildWarningsHelper so it can be unit-tested.
#
# Usage: count-build-warnings.rb [log_file_or_dir] [output_path]

require 'fileutils'
require 'json'
require_relative '../../fastlane/helpers/build_warnings_helper'

log_path = ARGV[0] || 'fastlane/logs'
output_path = ARGV[1] || 'build/build-warnings.json'
repo_root = ENV.fetch('BUILDKITE_BUILD_CHECKOUT_PATH', nil)
repo_root = `git rev-parse --show-toplevel 2>/dev/null`.strip if repo_root.nil? || repo_root.empty?
repo_root = Dir.pwd if repo_root.empty?

log_files = BuildWarningsHelper.collect_log_files(log_path)
abort("Build log path not found: #{log_path}") if log_files.nil?
abort("No build logs found under: #{log_path}") if log_files.empty?

report = BuildWarningsHelper.count_warnings(log_files: log_files, repo_root: repo_root, source: log_path)

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, "#{JSON.pretty_generate(report)}\n")

puts BuildWarningsHelper.report_summary_lines(report)
puts "Wrote build warning report to #{output_path}"
