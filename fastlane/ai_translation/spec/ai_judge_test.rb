# frozen_string_literal: true

require 'minitest/autorun'
require 'json'

require_relative '../lib/woo_ai_translation/ai_judge'
require_relative '../lib/woo_ai_translation/shadow_diff'

# Custom stub OpenAI client that returns a canned response per call. Lets us
# program "model said X for entry Y" without spending tokens.
class ProgrammableJudgeStub
  def initialize(verdict: 'equivalent', reasoning: 'looks fine')
    @default = { verdict: verdict, reasoning: reasoning }
    @per_call = {}
    @calls = 0
  end

  attr_reader :calls

  def with_response_for_call(call_number, verdict:, reasoning:)
    @per_call[call_number] = { verdict: verdict, reasoning: reasoning }
    self
  end

  def with_raw_response(raw_string)
    @raw_override = raw_string
    self
  end

  def available?
    true
  end

  def complete(messages:, model: nil, **)
    _ = [messages, model]
    @calls += 1
    return @raw_override if @raw_override

    response = @per_call[@calls] || @default
    JSON.generate(response)
  end
end

class AiJudgeTest < Minitest::Test
  def make_entry(key, en, gp, ai)
    WooAiTranslation::ShadowDiff::Entry.new(
      key: key, en_source: en, gp_human: gp, ai_proposal: ai,
      bucket: :substantive, en_placeholders: [], gp_placeholders: [], ai_placeholders: []
    )
  end

  def test_judge_returns_verdict_and_reasoning_for_valid_response
    # Given a stub that returns a well-formed JSON verdict
    stub = ProgrammableJudgeStub.new(verdict: 'acceptable_variant', reasoning: 'both fine')
    judge = WooAiTranslation::AiJudge.new(client: stub)

    # When we judge one triple
    result = judge.judge(en_source: 'Hello', gp_human: 'Hallo', ai_proposal: 'Hi')

    # Then we get the parsed verdict + reasoning
    assert_equal 'acceptable_variant', result[:verdict]
    assert_equal 'both fine', result[:reasoning]
  end

  def test_judge_returns_error_verdict_on_non_json_response
    # Given a stub that returns garbage
    stub = ProgrammableJudgeStub.new.with_raw_response('not valid json at all')
    judge = WooAiTranslation::AiJudge.new(client: stub)

    # When we judge
    result = judge.judge(en_source: 'x', gp_human: 'y', ai_proposal: 'z')

    # Then we get an error verdict instead of a raised exception
    assert_equal 'error', result[:verdict]
    assert_match(/judge error/, result[:reasoning])
  end

  def test_judge_returns_invalid_verdict_when_response_uses_unknown_label
    # Given a stub returning a JSON object with an unrecognized verdict
    stub = ProgrammableJudgeStub.new.with_raw_response(
      JSON.generate(verdict: 'something_made_up', reasoning: 'whatever')
    )
    judge = WooAiTranslation::AiJudge.new(client: stub)

    # When we judge
    result = judge.judge(en_source: 'x', gp_human: 'y', ai_proposal: 'z')

    # Then the verdict is replaced with `invalid_verdict` (defensive)
    assert_equal 'invalid_verdict', result[:verdict]
    assert_equal 'whatever', result[:reasoning]
  end

  def test_judge_strips_markdown_code_fences_from_response
    # Given a stub that wraps the JSON in ```json fences (a common LLM habit)
    fenced = "```json\n#{JSON.generate(verdict: 'equivalent', reasoning: 'fine')}\n```"
    stub = ProgrammableJudgeStub.new.with_raw_response(fenced)
    judge = WooAiTranslation::AiJudge.new(client: stub)

    # When we judge
    result = judge.judge(en_source: 'x', gp_human: 'y', ai_proposal: 'z')

    # Then the fences are stripped and the verdict parses
    assert_equal 'equivalent', result[:verdict]
  end

  def test_judge_passes_model_to_client
    # Given a stub that records the model parameter
    seen_models = []
    stub = Class.new do
      define_method(:available?) { true }
      define_method(:complete) do |messages:, model: nil, **|
        _ = messages
        seen_models << model
        JSON.generate(verdict: 'equivalent', reasoning: '')
      end
    end.new
    judge = WooAiTranslation::AiJudge.new(client: stub, model: 'gpt-5.1-mini')

    # When we judge
    judge.judge(en_source: 'x', gp_human: 'y', ai_proposal: 'z')

    # Then the configured model is passed through
    assert_equal ['gpt-5.1-mini'], seen_models
  end

  def test_judge_all_returns_per_entry_advisory_strings_for_worksheet
    # Given two entries and a stub that returns different verdicts per call
    stub = ProgrammableJudgeStub.new(verdict: 'equivalent', reasoning: 'fine')
    stub.with_response_for_call(2, verdict: 'ai_wrong', reasoning: 'misses meaning')
    judge = WooAiTranslation::AiJudge.new(client: stub)

    entries = [
      make_entry('k1', 'Hello', 'Hallo', 'Hi'),
      make_entry('k2', 'Save', 'Speichern', 'Stoppen')
    ]

    # When we judge all
    out = judge.judge_all(entries)

    # Then we get a Hash<key, String> with the verdict and reasoning formatted
    # for the worksheet's advisory column
    assert_equal 2, out.size
    assert_includes out['k1'], 'equivalent'
    assert_includes out['k1'], 'fine'
    assert_includes out['k2'], 'ai_wrong'
    assert_includes out['k2'], 'misses meaning'
  end

  def test_judge_all_continues_after_a_single_entry_fails
    # Given a stub that fails on call #1 but succeeds on call #2
    stub = ProgrammableJudgeStub.new(verdict: 'equivalent', reasoning: 'ok')
    # Make call #1 return garbage; call #2 returns the default
    def stub.complete(messages:, model: nil, **)
      _ = [messages, model]
      @calls += 1
      return 'garbage' if @calls == 1

      JSON.generate(verdict: @default[:verdict], reasoning: @default[:reasoning])
    end

    judge = WooAiTranslation::AiJudge.new(client: stub)
    entries = [
      make_entry('k1', 'a', 'b', 'c'),
      make_entry('k2', 'a', 'b', 'c')
    ]

    out = judge.judge_all(entries)

    # Both entries are present; the first reports an error verdict, the second succeeds.
    assert_equal 2, out.size
    assert_includes out['k1'], 'error'
    assert_includes out['k2'], 'equivalent'
  end
end
