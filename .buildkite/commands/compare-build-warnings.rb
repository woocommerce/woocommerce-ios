#!/usr/bin/env ruby
# frozen_string_literal: true

# Compares a PR build warning report against the PR base baseline report and
# prints the PR comment markdown to stdout. Prints nothing (and explains on
# stderr) when no comment is warranted, so the calling step can delete any
# stale comment. Logic lives in BuildWarningsHelper so it can be unit-tested.
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
  # The guard is advisory-only: degrade malformed reports or unexpected
  # errors to "no comment" (the calling step then deletes any stale comment)
  # instead of failing the CI step.
  warn "Build warning comparison failed: #{e.class}: #{e.message}"
  exit 0
end

if result[:skip]
  warn result[:skip]
else
  puts result[:comment]
end
