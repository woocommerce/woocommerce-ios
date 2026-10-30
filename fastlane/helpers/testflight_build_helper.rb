# frozen_string_literal: true

# Pure-Ruby helpers for the on-demand TestFlight build lane,
# `build_and_upload_testflight_build`.
#
# Deliberately free of Fastlane dependencies so the build-code and changelog
# rules can be exercised by unit tests without the Fastlane runtime: the caller
# passes the Buildkite environment in.
module TestFlightBuildHelper
  # Raised when the lane runs somewhere that isn't a Buildkite job, where there
  # is no build number to derive a unique build code from.
  class MissingBuildNumberError < StandardError; end

  module_function

  # Number of parts in a WooCommerce iOS build code, e.g. `25.3.0.4567`.
  BUILD_CODE_PARTS = 4

  # Build code for an on-demand TestFlight build: the release version zero-padded to
  # `BUILD_CODE_PARTS - 1` parts, with the Buildkite build number as the last part.
  #
  # Buildkite build numbers increase monotonically, so each build for a given release version gets
  # a unique, higher build code — which is all App Store Connect requires.
  #
  # @param release_version [String] the marketing version, e.g. `25.3` or `25.3.1` for a hotfix
  # @param buildkite_build_number [String, nil] the value of `$BUILDKITE_BUILD_NUMBER`
  #
  # @raise [MissingBuildNumberError] when the build number is missing or blank
  #
  def build_code(release_version:, buildkite_build_number:)
    raise MissingBuildNumberError, 'BUILDKITE_BUILD_NUMBER is not set — this lane is meant to run on CI' if buildkite_build_number.to_s.strip.empty?

    leading_parts = release_version.to_s.split('.')
    leading_parts = leading_parts.fill('0', leading_parts.length...(BUILD_CODE_PARTS - 1)).first(BUILD_CODE_PARTS - 1)

    [*leading_parts, buildkite_build_number.to_s.strip].join('.')
  end

  # The "What to Test" text shown to internal testers, naming the branch and commit the build
  # came from. These builds are triggered ad hoc, so the source is the only thing worth saying.
  #
  # @param branch [String, nil] the value of `$BUILDKITE_BRANCH`
  # @param commit [String, nil] the value of `$BUILDKITE_COMMIT`
  #
  def changelog(branch:, commit:)
    branch = 'unknown branch' if branch.to_s.strip.empty?
    commit = commit.to_s.strip.empty? ? 'unknown commit' : commit.to_s.strip[0...7]

    "Automated build from #{branch} (#{commit})."
  end
end
