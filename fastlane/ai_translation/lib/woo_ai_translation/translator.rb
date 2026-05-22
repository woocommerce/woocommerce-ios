# frozen_string_literal: true

require 'json'

require_relative 'anthropic_client'

module WooAiTranslation
  # Builds cached prompts, batches keys into structured JSON in/out calls, and
  # parses the response. On a parse/coverage failure it splits the batch and
  # retries; a key that still fails is returned untranslated so the caller can
  # report it rather than ship garbage.
  #
  # Adapted from the woocommerce-android engine (Phase 2 / PR #15962): same
  # batching + retry + cache-flagged-system-block design, retuned for iOS
  # placeholder syntax (%@, %1$@ rather than %s, %1$s).
  class Translator
    DEFAULT_BATCH = 40

    SYSTEM_RULES = <<~RULES
      You are a professional software localizer for the WooCommerce iOS app.
      Translate UI strings from English into the requested locale.

      Hard rules:
      - Preserve every placeholder EXACTLY: %@, %1$@, %2$@, %d, %1$d, %ld, %lld,
        %.0f, %@%%, %% etc. Keep the same count and the same positional indexes.
        Never translate, reorder or split the placeholder tokens themselves.
      - Preserve any inline markup/HTML tags (<b>, <a href="...">, etc.) and
        their attributes unchanged; translate only the human-readable text.
      - Keep escape sequences (\\n, \\t, \\") intact.
      - Do NOT merge or "fix" singular/plural variants. Each item is translated
        independently and literally for its grammatical number as given.
      - Keep brand names (WooCommerce, Woo, WordPress.com, Jetpack, Stripe,
        Apple Pay, PayPal) untranslated.
      - Match the tone of concise mobile UI copy. Do not add notes or quotes.

      Respond with ONLY a single minified JSON object mapping each input "id" to
      its translated string. No prose, no code fences.
    RULES

    def initialize(client:, batch_size: DEFAULT_BATCH, logger: nil)
      @client = client
      @batch_size = batch_size
      @logger = logger
    end

    # items: [{ id:, source:, context: }] ; returns { id => translation }.
    def translate(locale:, items:, model:, style: nil)
      result = {}
      items.each_slice(@batch_size) do |slice|
        result.merge!(translate_slice(locale: locale, items: slice, model: model, style: style))
      end
      result
    end

    private

    def translate_slice(locale:, items:, model:, style:)
      raw = @client.complete(
        model: model,
        system_blocks: system_blocks(locale, style),
        user_content: user_content(locale, items)
      )
      parsed = parse(raw)
      covered = items.select { |i| parsed.key?(i[:id]) }.size

      return parsed if covered == items.size
      return split_retry(locale, items, model, style) if items.size > 1

      log("unparseable translation for #{items.first[:id]} (#{locale}); left untranslated")
      {}
    rescue JSON::ParserError, AnthropicClient::Error => e
      raise if items.size <= 1 && !e.is_a?(JSON::ParserError)

      items.size > 1 ? split_retry(locale, items, model, style) : {}
    end

    def split_retry(locale, items, model, style)
      mid = items.size / 2
      translate_slice(locale: locale, items: items[0...mid], model: model, style: style)
        .merge(translate_slice(locale: locale, items: items[mid..], model: model, style: style))
    end

    def system_blocks(locale, style)
      # First block: constant rules. Last block: per-locale style guide. The
      # client cache-flags the last block so the whole prefix is prompt-cached.
      [SYSTEM_RULES, "Target locale: #{locale}.\n#{style || default_style(locale)}"]
    end

    def default_style(locale)
      "Use natural, idiomatic #{locale} as used in modern mobile commerce apps. " \
        'Prefer concise phrasing that fits small screens.'
    end

    def user_content(locale, items)
      payload = items.map { |i| { id: i[:id], source: i[:source], context: i[:context].to_s } }
      "locale: #{locale}\nTranslate every item; respond with the JSON object only.\n" \
        "#{JSON.generate(payload)}"
    end

    def parse(raw)
      text = raw.to_s.strip
      text = text.gsub(/\A```(?:json)?/, '').gsub(/```\z/, '').strip
      obj = JSON.parse(text)
      raise JSON::ParserError, 'expected object' unless obj.is_a?(Hash)

      obj
    end

    def log(msg)
      @logger&.call(msg)
    end
  end
end
