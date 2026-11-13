# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'support/should_skip_job_fixture'

# Pins which PR changes skip the build and test jobs, through the real `pr_changed_files` from the CI toolkit.
class ShouldSkipJobTest < Minitest::Test
  def self.fixture
    @fixture ||= ShouldSkipJobFixture.new.tap { |fixture| Minitest.after_run { fixture.close } }
  end

  def setup
    skip 'pr_changed_files not on PATH; add the a8c-ci-toolkit bin directory to run these' unless ShouldSkipJobFixture.pr_changed_files
    @fixture = self.class.fixture
  end

  %w[build validation].each do |job_type|
    define_method("test_#{job_type}_runs_when_the_fastfile_changes") do
      refute @fixture.skips?(job_type, ['fastlane/Fastfile'])
    end

    define_method("test_#{job_type}_runs_when_a_fastlane_helper_changes") do
      refute @fixture.skips?(job_type, ['fastlane/helpers/build_warnings_helper.rb'])
    end

    define_method("test_#{job_type}_runs_when_the_fastlane_env_changes") do
      refute @fixture.skips?(job_type, ['fastlane/env/user.env-example'])
    end

    define_method("test_#{job_type}_skips_when_only_store_content_changes") do
      assert @fixture.skips?(job_type, ['fastlane/metadata/en-US/nested/name.txt', 'fastlane/appstoreres/a.png', 'fastlane/screenshots.json'])
    end

    define_method("test_#{job_type}_skips_when_only_a_fastlane_helper_test_changes") do
      assert @fixture.skips?(job_type, ['fastlane/helpers/build_warnings_helper_test.rb'])
    end

    define_method("test_#{job_type}_skips_when_only_docs_and_gems_change") do
      assert @fixture.skips?(job_type, ['docs/a.md', 'Gemfile.lock'])
    end

    define_method("test_#{job_type}_runs_when_code_changes_alongside_skippable_files") do
      refute @fixture.skips?(job_type, ['fastlane/metadata/x.txt', 'WooCommerce/Classes/A.swift'])
    end
  end

  def test_validation_skips_when_only_localizations_change
    assert @fixture.skips?('validation', ['WooCommerce/Resources/en.lproj/Localizable.strings'])
  end

  def test_build_runs_when_localizations_change
    refute @fixture.skips?('build', ['WooCommerce/Resources/en.lproj/Localizable.strings'])
  end
end
