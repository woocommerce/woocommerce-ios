# frozen_string_literal: true

# Pure-Ruby unit tests for ReleaseNotesAIHelper. Uses Ruby's stdlib Minitest so
# no extra gems are required.
#
# Run:
#   ruby fastlane/helpers/release_notes_ai_helper_test.rb

require 'minitest/autorun'
require_relative 'release_notes_ai_helper'

# Unit tests for ReleaseNotesAIHelper.
class ReleaseNotesAIHelperTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  Helper = ReleaseNotesAIHelper

  # --- length_validation_tool ------------------------------------------------

  def test_length_validation_tool_has_expected_shape
    tool = Helper.length_validation_tool
    function = tool[:function]
    parameters = function[:parameters]

    assert_equal 'function', tool[:type]
    assert_equal Helper::LENGTH_VALIDATION_TOOL_NAME, function[:name]
    assert_equal 'object', parameters[:type]
    assert_equal %w[text], parameters[:required]
    assert_equal 'string', parameters[:properties][:text][:type]
  end

  def test_length_validation_tool_description_mentions_protocol_keys
    description = Helper.length_validation_tool[:function][:description]
    assert_includes description, '{ ok: true, length: }'
    assert_includes description, '{ ok: false, length:, max:, cut_at_least?, reason? }'
  end

  # --- build_length_validator: accepted drafts -------------------------------

  def test_build_length_validator_accepts_text_within_limit
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => 'Short copy.' })

    assert_equal({ ok: true, length: 'Short copy.'.length }, result)
    assert_equal 'Short copy.', captured[:text]
  end

  def test_build_length_validator_accepts_text_at_exact_limit
    text = 'a' * 350
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => text })

    assert_equal({ ok: true, length: 350 }, result)
    assert_equal text, captured[:text]
  end

  def test_build_length_validator_strips_surrounding_whitespace
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => "  Short copy.  \n" })

    assert_equal({ ok: true, length: 'Short copy.'.length }, result)
    assert_equal 'Short copy.', captured[:text]
  end

  # --- build_length_validator: rejected drafts -------------------------------

  def test_build_length_validator_rejects_text_over_limit_with_cut_at_least
    handler, captured = Helper.build_length_validator(max_length: 10)

    result = handler.call({ 'text' => 'x' * 15 })

    assert_equal({ ok: false, length: 15, max: 10, cut_at_least: 5 }, result)
    assert_nil captured[:text]
  end

  def test_build_length_validator_rejects_empty_text_with_reason
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => '' })

    assert_equal false, result[:ok]
    assert_equal 0, result[:length]
    assert_equal 350, result[:max]
    refute_nil result[:reason]
    refute result.key?(:cut_at_least)
    assert_nil captured[:text]
  end

  def test_build_length_validator_treats_whitespace_only_text_as_empty
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => "   \n  " })

    assert_equal false, result[:ok]
    assert_equal 0, result[:length]
    assert_equal 350, result[:max]
    refute_nil result[:reason]
    assert_nil captured[:text]
  end

  def test_build_length_validator_treats_nil_text_as_empty
    handler, captured = Helper.build_length_validator(max_length: 350)

    result = handler.call({ 'text' => nil })

    assert_equal false, result[:ok]
    assert_equal 0, result[:length]
    assert_nil captured[:text]
  end

  def test_build_length_validator_keeps_last_accepted_draft
    handler, captured = Helper.build_length_validator(max_length: 350)

    handler.call({ 'text' => 'First draft.' })
    handler.call({ 'text' => 'x' * 400 })
    handler.call({ 'text' => 'Second draft.' })

    # Capture reflects the most recent accepted draft; over-limit calls don't overwrite.
    assert_equal 'Second draft.', captured[:text]
  end

  # --- generate orchestration ------------------------------------------------

  def test_generate_yields_tools_and_handlers_and_returns_captured_text
    yielded = nil
    result = Helper.generate(max_length: 350) do |tools:, tool_handlers:|
      yielded = { tools: tools, tool_handlers: tool_handlers }
      # Simulate the model invoking the validation tool with an acceptable draft.
      tool_handlers[Helper::LENGTH_VALIDATION_TOOL_NAME].call({ 'text' => 'Accepted draft copy.' })
    end

    assert_equal 'Accepted draft copy.', result
    assert_equal 1, yielded[:tools].size
    assert_equal Helper::LENGTH_VALIDATION_TOOL_NAME, yielded[:tools].first[:function][:name]
    assert_includes yielded[:tool_handlers].keys, Helper::LENGTH_VALIDATION_TOOL_NAME
  end

  def test_generate_raises_when_tool_is_never_invoked
    error = assert_raises(Helper::ToolCallNotInvokedError) do
      Helper.generate(max_length: 350) do |tools:, tool_handlers:|
        # Simulate the model returning without invoking the tool.
        _ = [tools, tool_handlers]
      end
    end
    assert_includes error.message, Helper::LENGTH_VALIDATION_TOOL_NAME
  end

  def test_generate_returns_text_from_final_accepted_draft_after_retries
    result = Helper.generate(max_length: 20) do |tools:, tool_handlers:|
      handler = tool_handlers[Helper::LENGTH_VALIDATION_TOOL_NAME]
      # Simulate over-limit attempt first, then a corrected one.
      handler.call({ 'text' => 'x' * 25 })
      handler.call({ 'text' => 'Fits.' })
      _ = tools
    end

    assert_equal 'Fits.', result
  end

  def test_generate_raises_argument_error_without_block
    assert_raises(ArgumentError) do
      Helper.generate(max_length: 350)
    end
  end
end
