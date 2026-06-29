# frozen_string_literal: true

# Pure-Ruby unit tests for XcconfigHelper. Uses Ruby's stdlib Minitest so no
# extra gems are required.
#
# Run:
#   ruby fastlane/helpers/xcconfig_helper_test.rb

require 'minitest/autorun'
require_relative 'xcconfig_helper'

# Unit tests for XcconfigHelper.
class XcconfigHelperTest < Minitest::Test
  Helper = XcconfigHelper

  def test_value_reads_the_setting
    assert_equal 'PZYM8XX95Q', Helper.value("DEVELOPMENT_TEAM = PZYM8XX95Q\n", 'DEVELOPMENT_TEAM')
  end

  def test_value_tolerates_surrounding_whitespace
    assert_equal '99KV9Z6BKV', Helper.value("  DEVELOPMENT_TEAM=99KV9Z6BKV  \n", 'DEVELOPMENT_TEAM')
  end

  def test_value_ignores_commented_out_lines
    contents = <<~XCCONFIG
      // DEVELOPMENT_TEAM = COMMENTEDOUT
      DEVELOPMENT_TEAM = REALVALUE
    XCCONFIG
    assert_equal 'REALVALUE', Helper.value(contents, 'DEVELOPMENT_TEAM')
  end

  def test_value_ignores_includes_and_unrelated_keys
    contents = <<~XCCONFIG
      #include "Common.xcconfig"
      OTHER_KEY = nope
      DEVELOPMENT_TEAM = TEAMID
    XCCONFIG
    assert_equal 'TEAMID', Helper.value(contents, 'DEVELOPMENT_TEAM')
  end

  def test_value_stops_at_inline_comment
    assert_equal 'TEAMID', Helper.value('DEVELOPMENT_TEAM = TEAMID // App Store account', 'DEVELOPMENT_TEAM')
  end

  def test_value_returns_nil_when_absent
    assert_nil Helper.value("OTHER_KEY = value\n", 'DEVELOPMENT_TEAM')
  end

  def test_value_does_not_match_a_prefixed_key
    assert_nil Helper.value("MY_DEVELOPMENT_TEAM = value\n", 'DEVELOPMENT_TEAM')
  end
end
