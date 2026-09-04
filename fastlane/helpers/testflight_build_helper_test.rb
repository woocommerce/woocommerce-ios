# frozen_string_literal: true

# Pure-Ruby unit tests for TestFlightBuildHelper. Uses Ruby's stdlib Minitest so
# no extra gems are required.
#
# Run:
#   ruby fastlane/helpers/testflight_build_helper_test.rb

require 'minitest/autorun'
require_relative 'testflight_build_helper'

# Unit tests for TestFlightBuildHelper.
class TestFlightBuildHelperTest < Minitest::Test
  Helper = TestFlightBuildHelper

  # --- build_code ------------------------------------------------------------

  def test_build_code_appends_the_buildkite_build_number_to_a_four_part_version
    assert_equal '25.3.0.4567', Helper.build_code(release_version: '25.3', buildkite_build_number: '4567')
  end

  def test_build_code_stays_four_parts_for_a_hotfix_release_version
    assert_equal '25.3.1.4567', Helper.build_code(release_version: '25.3.1', buildkite_build_number: '4567')
  end

  def test_build_code_is_always_four_parts
    ['25', '25.3', '25.3.1'].each do |release_version|
      code = Helper.build_code(release_version: release_version, buildkite_build_number: '4567')

      assert_equal 4, code.split('.').length, "expected a four-part build code for #{release_version}, got #{code}"
    end
  end

  def test_build_code_sorts_higher_as_the_buildkite_build_number_grows
    earlier = Helper.build_code(release_version: '25.3', buildkite_build_number: '9')
    later = Helper.build_code(release_version: '25.3', buildkite_build_number: '10')

    assert_operator Gem::Version.new(later), :>, Gem::Version.new(earlier)
  end

  def test_build_code_accepts_an_integer_build_number
    assert_equal '25.3.0.4567', Helper.build_code(release_version: '25.3', buildkite_build_number: 4567)
  end

  def test_build_code_raises_when_the_build_number_is_missing
    assert_raises(Helper::MissingBuildNumberError) do
      Helper.build_code(release_version: '25.3', buildkite_build_number: nil)
    end
  end

  def test_build_code_raises_when_the_build_number_is_blank
    assert_raises(Helper::MissingBuildNumberError) do
      Helper.build_code(release_version: '25.3', buildkite_build_number: '  ')
    end
  end

  # --- changelog -------------------------------------------------------------

  def test_changelog_names_the_branch_and_the_short_commit
    assert_equal 'Automated build from trunk (abc1234).', Helper.changelog(branch: 'trunk', commit: 'abc1234def5678')
  end

  def test_changelog_leaves_a_commit_shorter_than_seven_characters_alone
    assert_equal 'Automated build from trunk (abc12).', Helper.changelog(branch: 'trunk', commit: 'abc12')
  end

  def test_changelog_falls_back_when_the_buildkite_environment_is_absent
    assert_equal 'Automated build from unknown branch (unknown commit).', Helper.changelog(branch: nil, commit: nil)
  end
end
