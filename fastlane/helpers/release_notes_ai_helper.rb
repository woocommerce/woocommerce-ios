# frozen_string_literal: true

# Pure-Ruby helpers for the AI release-notes generation loop used by
# `create_release_notes_pr`.
#
# Encapsulates the `openai_ask` tool-use logic: the length-validation tool
# definition, the handler that backs it, and the orchestration that drives a
# Fastlane-side `openai_ask` call until the model produces a valid draft.
#
# Deliberately free of Fastlane / network / openai_ask dependencies so the
# logic can be exercised by unit tests without touching the network or the
# Fastlane runtime: the caller injects the actual ask via a block.
module ReleaseNotesAIHelper
  # Raised when the model finished its turn without invoking the
  # `validate_release_notes_length` tool — meaning we never captured an
  # accepted draft. Distinct from a draft that was rejected for being empty
  # (the handler keeps the loop going in that case).
  class ToolCallNotInvokedError < StandardError; end

  # Name of the OpenAI tool the model uses to submit drafts for length
  # validation. Exposed so callers can build the `tool_handlers` map without
  # duplicating the string.
  LENGTH_VALIDATION_TOOL_NAME = 'validate_release_notes_length'

  module_function

  # Drives an `openai_ask` tool-use loop that enforces the release-notes
  # length limit. The caller is expected to invoke `openai_ask` (or another
  # equivalent) inside the block, threading `tools:` and `tool_handlers:`
  # through verbatim. The accepted draft is returned by reading the captured
  # value the handler stashes — not the model's final plain-text turn — so
  # the returned text is exactly what passed length validation.
  #
  # @param max_length [Integer] max allowed length for the validated draft
  # @yieldparam tools [Array<Hash>] OpenAI tool definitions
  # @yieldparam tool_handlers [Hash{String=>#call}] handler keyed by tool name
  # @return [String] the accepted release-notes text
  # @raise [ToolCallNotInvokedError] if the model never called the tool
  def generate(max_length:)
    raise ArgumentError, 'a block is required' unless block_given?

    handler, captured = build_length_validator(max_length: max_length)
    yield(tools: [length_validation_tool], tool_handlers: { LENGTH_VALIDATION_TOOL_NAME => handler })

    captured_text = captured[:text]
    if captured_text.nil?
      raise ToolCallNotInvokedError,
            "openai_ask returned without invoking #{LENGTH_VALIDATION_TOOL_NAME} — " \
            'check that the model supports tool calling.'
    end

    captured_text
  end

  # Builds the `validate_release_notes_length` tool handler. Returns
  # `[handler, captured]`: the lambda the toolkit invokes, and a 1-key Hash
  # whose `:text` field is set to the accepted draft when the model produces
  # one. The Hash is used as a writable capture slot — closing over a plain
  # local would force the caller to share its scope with the lambda, which
  # is fine but forces the whole flow into one method.
  #
  # Validation rules:
  # - strip leading/trailing whitespace so it never lands in `release_notes.txt`
  #   or `CHANGELOG.md` and doesn't inflate the character count
  # - reject empty drafts as a length-style failure so the model stays in the
  #   loop instead of terminating early and being caught later as "empty
  #   release notes"
  # - on success, capture the validated text and tell the model `ok: true, length:`
  # - on overshoot, tell the model how many characters to cut via `cut_at_least`
  # - on empty, tell the model via `reason` (no `cut_at_least` since the action
  #   is to add content, not trim) — both rejection shapes share the
  #   `ok: false, length:, max:` keys
  #
  # @param max_length [Integer]
  # @return [Array(Proc, Hash)] [handler, captured]
  def build_length_validator(max_length:)
    captured = { text: nil }
    handler = lambda do |args|
      text = args['text'].to_s.strip
      length = text.length
      if length.zero?
        { ok: false, length: 0, max: max_length, reason: 'empty draft — submit a non-empty paragraph' }
      elsif length <= max_length
        captured[:text] = text
        { ok: true, length: length }
      else
        { ok: false, length: length, max: max_length, cut_at_least: length - max_length }
      end
    end
    [handler, captured]
  end

  # OpenAI tool definition for `validate_release_notes_length`.
  def length_validation_tool
    {
      type: 'function',
      function: {
        name: LENGTH_VALIDATION_TOOL_NAME,
        description: 'Checks the length of the proposed release notes paragraph against the character limit. ' \
                     'Returns `{ ok: true, length: }` if the text fits, or `{ ok: false, length:, max:, cut_at_least?, reason? }` ' \
                     'otherwise — `cut_at_least` is included when the draft is too long; `reason` is included for other rejections ' \
                     '(e.g. an empty draft). Call this repeatedly with revised drafts until it returns `ok: true`. ' \
                     'When shortening, restructure or remove phrases or items — do not drop letters from words, ' \
                     'omit articles, or invent abbreviations to hit the limit. Grammar and spelling must remain correct.',
        parameters: {
          type: 'object',
          properties: {
            text: { type: 'string', description: 'The proposed release notes paragraph.' }
          },
          required: ['text']
        }
      }
    }
  end
end
