# frozen_string_literal: true

require 'openssl'

require_relative 'anthropic_client'
require_relative 'constants'
require_relative 'translator'
require_relative 'validator'

module WooAiTranslation
  # Orchestrates per-release App Store release-notes translation across the 14
  # AI-translated locales. Re-uses the existing `Translator` + `Validator`
  # plumbing with two release-notes-specific adaptations:
  #
  #   1. The source is a single plain-text blob, not a `.strings` document, so
  #      we synthesize a single translation item (id `release_notes`).
  #   2. Apple ASC caps release_notes at 4000 bytes. A locale whose translation
  #      exceeds that is treated as a soft failure (skipped, English falls
  #      back automatically) rather than a hard build failure — release_notes
  #      copy is short enough that overflow is extremely unlikely in practice
  #      and shipping English for one locale is preferable to blocking the
  #      release.
  #
  # On a Haiku-tier failure (empty translation, validator violation, length
  # overflow), we transparently retry with Opus per the engine's existing
  # escalation pattern. If Opus also fails, we mark the locale `:skipped` and
  # let Apple's automatic English fallback kick in. Callers receive a `Result`
  # per locale so they can decide how to surface the outcome (Buildkite
  # annotation, lane log, etc.).
  class ReleaseNotesTranslator
    # Apple's documented ASC release_notes byte limit. See `Fastfile`
    # `download_localized_metadata_from_glotpress` lane target_files entry.
    MAX_ASC_BYTES = 4000

    # Plain-text item id we feed to the JSON-in/JSON-out Translator. Arbitrary
    # but stable so a test can assert against it.
    ITEM_ID = 'release_notes'

    ITEM_CONTEXT = <<~CONTEXT.chomp
      App Store release notes — a single short paragraph (typically 200-500 chars)
      describing what changed in this release. Casual but professional tone for
      merchants. Preserve any URLs, code-like tokens, and brand names verbatim.
    CONTEXT

    # Outcome of translating one locale.
    # status: :translated | :skipped
    # skip_reason: nil when translated; otherwise short human-readable string
    Result = Struct.new(
      :locale, :asc_locale, :status, :model, :translation, :skip_reason,
      keyword_init: true
    )

    def initialize(client:, glossary_dir:, style_dir: nil, logger: nil)
      @client = client
      @translator = Translator.new(client: client, logger: logger)
      @glossary_dir = glossary_dir
      @style_dir = style_dir
      @logger = logger
    end

    # Translate `source_text` into `locale`, returning a `Result`. Tries Haiku
    # first; on failure (empty, validator violation, length overflow) retries
    # with Opus. A second failure yields a `:skipped` result.
    def translate(source_text:, locale:, asc_locale:)
      first = attempt(source_text, locale, asc_locale, DEFAULT_MODEL)
      return first if first.status == :translated

      log("#{locale}: retrying with Opus — #{first.skip_reason}")
      second = attempt(source_text, locale, asc_locale, ESCALATION_MODEL)
      return second if second.status == :translated

      log("#{locale}: skipped after Opus retry — #{second.skip_reason}")
      second
    end

    private

    def attempt(source_text, locale, asc_locale, model)
      raw = call_translator(source_text, locale, model, load_style(locale))
      reason = check_raw(raw, source_text, locale)

      Result.new(
        locale: locale,
        asc_locale: asc_locale,
        model: model,
        status: reason ? :skipped : :translated,
        translation: reason ? nil : raw,
        skip_reason: reason
      )
    rescue AnthropicClient::Error,
           Net::OpenTimeout, Net::ReadTimeout,
           SystemCallError, SocketError, IOError,
           OpenSSL::SSL::SSLError => e
      # `Translator#translate_slice` re-raises `AnthropicClient::Error` (and
      # leaves network timeouts unhandled) when the batch has a single item —
      # which is always our case for release_notes. The underlying
      # `Net::HTTP.request` in `AnthropicClient` can also raise socket-level
      # exceptions (`Errno::ECONNRESET`, `SocketError`, `EOFError`,
      # `OpenSSL::SSL::SSLError`) that `with_retries` does not catch. Without
      # this broad rescue, any of those would kill the lane instead of
      # flowing through the Haiku→Opus retry → English-fallback path.
      # Surface the failure as a soft `:skipped` result so `translate` can
      # try Opus, and so a final failure stays within the documented "ship
      # English for the failed locale" contract.
      Result.new(
        locale: locale,
        asc_locale: asc_locale,
        model: model,
        status: :skipped,
        translation: nil,
        skip_reason: "client error: #{e.class.name.split('::').last} (#{e.message})"
      )
    end

    # Returns `nil` if `raw` is an acceptable translation, otherwise a short
    # human-readable string describing the failure.
    def check_raw(raw, source_text, locale)
      return 'empty or missing translation' if raw.nil? || raw.strip.empty?
      return "exceeds #{MAX_ASC_BYTES} bytes (got #{raw.bytesize})" if raw.bytesize > MAX_ASC_BYTES

      violations = Validator.for_locale(locale: locale, base_dir: @glossary_dir)
                            .validate(source: source_text, translation: raw)
      return nil if violations.empty?

      details = violations.map { |v| "#{v[:rule]}:#{v[:term]}" }.join(', ')
      "validator failed (#{details})"
    end

    def call_translator(source_text, locale, model, style)
      items = [{ id: ITEM_ID, source: source_text, context: ITEM_CONTEXT }]
      out = @translator.translate(locale: locale, items: items, model: model, style: style)
      out[ITEM_ID]
    end

    def load_style(locale)
      return nil if @style_dir.nil?

      path = File.join(@style_dir, "#{locale}.md")
      File.exist?(path) ? File.read(path) : nil
    end

    def log(msg)
      @logger&.call(msg)
    end
  end
end
