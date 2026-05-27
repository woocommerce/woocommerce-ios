# frozen_string_literal: true

require 'json'

require_relative 'openai_client'

module WooAiTranslation
  # Tier 2 of the shadow-diff calibration tool.
  #
  # Calls an LLM (typically GPT-5.1 via `OpenAIClient`, deliberately a
  # different model family from the Anthropic-based production translator) to
  # classify each Substantive-bucket diff as one of:
  #
  #   - equivalent          — both convey the same meaning equally well
  #   - acceptable_variant  — both are correct, slight style/word-choice
  #   - different_meaning   — the two translations mean different things
  #   - ai_wrong            — AI proposal misses/changes source meaning
  #   - gp_wrong            — GP human is wrong; AI proposal is correct
  #
  # The output is **advisory only**. It must never replace Tier 3 (human
  # native-speaker review). The worksheet column is labeled accordingly. See
  # README "Shadow-diff calibration" for why AI-judging-AI is biased and why
  # the human reviewer remains the decision-maker.
  #
  # Calls are intentionally one-at-a-time rather than batched: the judge
  # operates only on the worksheet sample (typically <100 entries per locale,
  # bounded by `SAMPLE_POLICY`), so total call count is manageable without
  # adding JSON-batch parsing complexity.
  class AiJudge
    DEFAULT_MODEL = WooAiTranslation::OpenAIClient::DEFAULT_MODEL

    SYSTEM_PROMPT = <<~PROMPT
      You are evaluating two translations of the same English UI string from a
      mobile commerce app called WooCommerce. The audience is small-business
      merchants managing their store from a phone. Brand names like WooCommerce,
      Stripe, Apple Pay, WordPress.com must appear verbatim in any translation.

      You will receive three lines:
        EN source: <the English original>
        GP human: <the existing human translation>
        AI proposal: <a candidate AI translation>

      Compare GP and AI for this audience and classify their relationship as
      ONE of:
        - "equivalent"          — both convey the same meaning equally well
        - "acceptable_variant"  — both are correct, slight style/word-choice difference
        - "different_meaning"   — the two translations mean different things
        - "ai_wrong"            — AI proposal misses/changes source meaning; GP is correct
        - "gp_wrong"            — GP human is wrong (e.g. outdated, typo); AI is correct

      Respond with ONLY a single minified JSON object with two keys:
        "verdict": one of the labels above (string)
        "reasoning": one short sentence (max 120 chars)

      No prose outside the JSON. No code fences. No additional keys.
    PROMPT

    VALID_VERDICTS = %w[equivalent acceptable_variant different_meaning ai_wrong gp_wrong].freeze

    def initialize(client:, model: DEFAULT_MODEL)
      @client = client
      @model = model
    end

    # Public: judge a list of `ShadowDiff::Entry` records.
    # Returns Hash<entry.key => String> with one-line "verdict: reasoning"
    # strings ready to drop into the worksheet's `Judge (advisory)` column.
    # Errors per entry are surfaced as "error: <message>" rather than raised,
    # so a partial judge run still produces a usable worksheet.
    def judge_all(entries)
      entries.to_h do |entry|
        result = judge(
          en_source: entry.en_source,
          gp_human: entry.gp_human,
          ai_proposal: entry.ai_proposal
        )
        [entry.key, format_cell(result)]
      end
    end

    # Public: judge one (en, gp, ai) triple.
    # Returns { verdict: String, reasoning: String }. On error, returns
    # { verdict: "error", reasoning: "<message>" }.
    def judge(en_source:, gp_human:, ai_proposal:)
      messages = [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: format_question(en_source, gp_human, ai_proposal) }
      ]
      raw = @client.complete(messages: messages, model: @model)
      parse(raw)
    rescue StandardError => e
      { verdict: 'error', reasoning: "judge error: #{e.class.name.split('::').last} #{e.message}" }
    end

    private

    def format_question(en_source, gp_human, ai_proposal)
      "EN source: #{en_source}\nGP human: #{gp_human}\nAI proposal: #{ai_proposal}"
    end

    def parse(raw)
      text = raw.to_s.strip
      text = text.gsub(/\A```(?:json)?/, '').gsub(/```\z/, '').strip
      obj = JSON.parse(text)
      raise ArgumentError, 'expected JSON object' unless obj.is_a?(Hash)

      verdict = obj['verdict'].to_s
      reasoning = obj['reasoning'].to_s
      verdict = 'invalid_verdict' unless VALID_VERDICTS.include?(verdict)
      { verdict: verdict, reasoning: reasoning }
    end

    def format_cell(result)
      "**#{result[:verdict]}** — #{result[:reasoning]}"
    end
  end
end
