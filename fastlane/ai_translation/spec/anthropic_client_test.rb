# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/woo_ai_translation/anthropic_client'

# Guards the credential-leak fix: the client must never be constructable in a
# way that would transmit the API key over an unencrypted connection to a
# remote host.
class AnthropicClientTest < Minitest::Test
  Error = WooAiTranslation::AnthropicClient::Error

  def build(base_url, http: nil)
    WooAiTranslation::AnthropicClient.new(api_key: 'sk-test', base_url: base_url, http: http)
  end

  def test_accepts_https_base_url
    build('https://api.anthropic.com')
    build('https://gateway.internal.example.com/proxy')
  end

  def test_accepts_default_base_url
    WooAiTranslation::AnthropicClient.new(api_key: 'sk-test')
  end

  def test_accepts_plain_http_only_for_loopback
    build('http://localhost:8080')
    build('http://127.0.0.1:3000')
    build('http://[::1]:3000')
  end

  def test_rejects_plain_http_to_remote_host
    err = assert_raises(Error) { build('http://gateway.example.com') }
    assert_match(/insecure connection/, err.message)
  end

  def test_rejects_non_http_scheme
    assert_raises(Error) { build('ftp://api.anthropic.com') }
  end

  def test_rejects_malformed_base_url
    err = assert_raises(Error) { build('not a url') }
    assert_match(/Invalid base URL/, err.message)
  end

  def test_injected_transport_bypasses_url_guard
    # An injected transport (test double) owns its own security posture, so the
    # https guard does not apply — this must not raise.
    build('http://gateway.example.com', http: Object.new)
  end
end
