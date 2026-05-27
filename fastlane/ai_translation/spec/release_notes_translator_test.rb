# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'openssl'
require 'socket'

require_relative '../lib/woo_ai_translation/constants'
require_relative '../lib/woo_ai_translation/release_notes_translator'

# StubClient-style fake that lets a test program per-model behavior. The real
# StubClient ignores the `model:` argument; here we branch on it so we can
# exercise the Haiku → Opus escalation path deterministically.
#
# Each value in `behaviors_by_model` can be either:
#   - a Proc (locale, source) -> translation_string — for normal returns
#   - an Exception instance — to simulate a client/API failure on that model
class ModelAwareStubClient
  def initialize(behaviors_by_model)
    @behaviors = behaviors_by_model
    @calls = []
  end

  attr_reader :calls

  def available?
    true
  end

  def complete(model:, system_blocks:, user_content:, max_tokens: 8192)
    _ = [system_blocks, max_tokens] # unused in fake
    @calls << model
    behavior = @behaviors.fetch(model) { ->(_loc, _src) { '' } }
    raise behavior if behavior.is_a?(Exception)

    locale = user_content[/locale:\s*([\w-]+)/, 1] || '??'
    payload = JSON.parse(user_content[/\[.*\]/m] || '[]')
    out = payload.to_h { |item| [item['id'], behavior.call(locale, item['source'])] }
    JSON.generate(out)
  end
end

class ReleaseNotesTranslatorTest < Minitest::Test
  HAIKU = WooAiTranslation::DEFAULT_MODEL
  OPUS = WooAiTranslation::ESCALATION_MODEL

  def setup
    @glossary_dir = Dir.mktmpdir
    File.write(File.join(@glossary_dir, 'common.yml'), <<~YAML)
      brands:
        - WooCommerce
    YAML
    File.write(File.join(@glossary_dir, 'pl.yml'), <<~YAML)
      ui_terms: {}
      nouns: {}
    YAML
  end

  def teardown
    FileUtils.remove_entry(@glossary_dir) if @glossary_dir && File.exist?(@glossary_dir)
  end

  def make_translator(transforms)
    WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(transforms),
      glossary_dir: @glossary_dir
    )
  end

  def test_translate_when_haiku_succeeds_then_returns_translated_with_haiku_model
    # Given a Haiku response that passes validation
    t = make_translator(HAIKU => ->(loc, src) { "[#{loc}] #{src}" })

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then the translation succeeds on first attempt with Haiku
    assert_equal :translated, result.status
    assert_equal HAIKU, result.model
    assert_equal 'pl', result.locale
    assert_equal 'pl', result.asc_locale
    assert_equal '[pl] Welcome to WooCommerce', result.translation
    assert_nil result.skip_reason
  end

  def test_translate_when_haiku_returns_empty_then_retries_with_opus_and_succeeds
    # Given Haiku returns empty and Opus returns a valid translation
    client_transforms = {
      HAIKU => ->(_loc, _src) { '' },
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    stub = ModelAwareStubClient.new(client_transforms)
    t = WooAiTranslation::ReleaseNotesTranslator.new(client: stub, glossary_dir: @glossary_dir)

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then the result is :translated via Opus, both models were called
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
    assert_equal [HAIKU, OPUS], stub.calls
  end

  def test_translate_when_haiku_drops_brand_then_retries_with_opus_and_succeeds
    # Given Haiku returns a translation that drops "WooCommerce" (brand violation)
    # and Opus returns one that preserves it
    client_transforms = {
      HAIKU => ->(loc, _src) { "[#{loc}] Witaj w sklepie" },
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    stub = ModelAwareStubClient.new(client_transforms)
    t = WooAiTranslation::ReleaseNotesTranslator.new(client: stub, glossary_dir: @glossary_dir)

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we get an Opus-tier success
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
    assert_includes result.translation, 'WooCommerce'
  end

  def test_translate_when_haiku_exceeds_max_bytes_then_retries_with_opus_and_succeeds
    # Given Haiku returns a translation larger than MAX_ASC_BYTES (4000) and
    # Opus returns a short one
    long_payload = 'x' * (WooAiTranslation::ReleaseNotesTranslator::MAX_ASC_BYTES + 100)
    client_transforms = {
      HAIKU => ->(_loc, _src) { long_payload },
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(client_transforms),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Short source', locale: 'pl', asc_locale: 'pl')

    # Then we get an Opus-tier success
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_both_models_drop_brand_then_returns_skipped
    # Given both Haiku and Opus return translations that drop "WooCommerce"
    drop = ->(loc, _src) { "[#{loc}] Witaj w sklepie" }
    t = make_translator(HAIKU => drop, OPUS => drop)

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we get a skipped result whose reason names the validator rule
    assert_equal :skipped, result.status
    assert_equal OPUS, result.model
    assert_match(/validator/, result.skip_reason)
    assert_match(/brand_safety/, result.skip_reason)
    assert_nil result.translation
  end

  def test_translate_when_both_models_empty_then_returns_skipped_with_empty_reason
    # Given both models return empty
    empty = ->(_loc, _src) { '' }
    t = make_translator(HAIKU => empty, OPUS => empty)

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we get a skipped result citing the empty translation
    assert_equal :skipped, result.status
    assert_match(/empty/, result.skip_reason)
  end

  def test_translate_when_both_models_exceed_max_then_returns_skipped_with_size_reason
    # Given both models return oversized output
    huge = WooAiTranslation::ReleaseNotesTranslator::MAX_ASC_BYTES + 1
    over = ->(_loc, _src) { 'x' * huge }
    t = make_translator(HAIKU => over, OPUS => over)

    # When we translate
    result = t.translate(source_text: 'Short source', locale: 'pl', asc_locale: 'pl')

    # Then we get a skipped result citing the size overflow
    assert_equal :skipped, result.status
    assert_match(/exceeds/, result.skip_reason)
    assert_match(/4000/, result.skip_reason)
  end

  def test_translate_when_haiku_raises_api_error_then_retries_with_opus_and_succeeds
    # Given Haiku raises an AnthropicClient::Error (transient API failure)
    # and Opus returns a valid translation
    behaviors = {
      HAIKU => WooAiTranslation::AnthropicClient::Error.new('simulated haiku failure'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    stub = ModelAwareStubClient.new(behaviors)
    t = WooAiTranslation::ReleaseNotesTranslator.new(client: stub, glossary_dir: @glossary_dir)

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we get an Opus-tier success — the rescue caught the error and
    # let `translate` proceed to the escalation path.
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
    assert_equal [HAIKU, OPUS], stub.calls
  end

  def test_translate_when_both_models_raise_api_error_then_returns_skipped_with_client_error_reason
    # Given both Haiku and Opus raise the same API error
    behaviors = {
      HAIKU => WooAiTranslation::AnthropicClient::Error.new('haiku unavailable'),
      OPUS => WooAiTranslation::AnthropicClient::Error.new('opus also unavailable')
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then per-locale failure is soft: we get a :skipped Result citing the
    # client error, and the lane (caller) ships English for this locale.
    assert_equal :skipped, result.status
    assert_equal OPUS, result.model
    assert_match(/client error/, result.skip_reason)
    assert_match(/Error/, result.skip_reason)
  end

  def test_translate_when_haiku_raises_network_timeout_then_retries_with_opus
    # Given Haiku raises a network timeout (covered by the same rescue)
    behaviors = {
      HAIKU => Net::ReadTimeout.new('haiku timed out'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we get an Opus-tier success — network timeouts are recoverable too.
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_haiku_raises_econnreset_then_retries_with_opus
    # Given Haiku raises Errno::ECONNRESET — a `SystemCallError` subclass that
    # `Net::HTTP` propagates without retry. Verifies the rescue's
    # `SystemCallError` arm.
    behaviors = {
      HAIKU => Errno::ECONNRESET.new('connection reset by peer'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we recover via Opus
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_haiku_raises_socket_error_then_retries_with_opus
    # Given Haiku raises SocketError (DNS / connection setup failure).
    behaviors = {
      HAIKU => SocketError.new('getaddrinfo: nodename nor servname provided'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we recover via Opus
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_haiku_raises_eof_error_then_retries_with_opus
    # Given Haiku raises EOFError (mid-stream connection close, an IOError).
    behaviors = {
      HAIKU => EOFError.new('end of file reached'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we recover via Opus
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_haiku_raises_ssl_error_then_retries_with_opus
    # Given Haiku raises OpenSSL::SSL::SSLError (TLS handshake failure).
    behaviors = {
      HAIKU => OpenSSL::SSL::SSLError.new('SSL_connect returned=1'),
      OPUS => ->(loc, src) { "[#{loc}] #{src}" }
    }
    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(behaviors),
      glossary_dir: @glossary_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then we recover via Opus
    assert_equal :translated, result.status
    assert_equal OPUS, result.model
  end

  def test_translate_when_style_file_present_then_no_crash_and_translation_succeeds
    # Given a populated style directory
    style_dir = Dir.mktmpdir
    File.write(File.join(style_dir, 'pl.md'), '# Polish style notes')

    t = WooAiTranslation::ReleaseNotesTranslator.new(
      client: ModelAwareStubClient.new(HAIKU => ->(loc, src) { "[#{loc}] #{src}" }),
      glossary_dir: @glossary_dir,
      style_dir: style_dir
    )

    # When we translate
    result = t.translate(source_text: 'Welcome to WooCommerce', locale: 'pl', asc_locale: 'pl')

    # Then the translation still succeeds (smoke test for the style path)
    assert_equal :translated, result.status
  ensure
    FileUtils.remove_entry(style_dir) if style_dir && File.exist?(style_dir)
  end
end
