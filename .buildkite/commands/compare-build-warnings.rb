#!/usr/bin/env ruby
# frozen_string_literal: true

# Compares a PR build warning report against the PR base baseline report and
# prints the PR comment markdown to stdout. A successful empty result means
# no new warnings. An unavailable comparison exits nonzero so the calling
# step can distinguish it from a clean result and remain advisory-only.
#
# Usage: compare-build-warnings.rb [current_report.json] [baseline_report.json]

require 'json'
require_relative '../../fastlane/helpers/build_warnings_helper'

report_path = ARGV[0] || 'build-warnings.json'
baseline_report_path = ARGV[1] || 'base-build-warnings.json'

begin
  result = BuildWarningsHelper.build_comment(
    current: JSON.parse(File.read(report_path)),
    baseline: JSON.parse(File.read(baseline_report_path)),
    base_branch: ENV.fetch('BUILDKITE_PULL_REQUEST_BASE_BRANCH', 'trunk'),
    build_url: ENV.fetch('BUILDKITE_BUILD_URL', ''),
    repository_url: ENV.fetch('BUILDKITE_REPO', 'https://github.com/woocommerce/woocommerce-ios'),
    report_path: report_path,
    baseline_report_path: baseline_report_path
  )
rescue ScriptError, StandardError => e
  warn "Build warning comparison failed: #{e.class}: #{e.message}"
  exit 1
end

if result[:unavailable]
  warn result[:unavailable]
  exit 1
elsif result[:skip]
  warn result[:skip]
else
  puts result[:comment]
end
