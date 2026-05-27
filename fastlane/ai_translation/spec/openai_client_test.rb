# frozen_string_literal: true

require 'minitest/autorun'
require 'json'

require_relative '../lib/woo_ai_translation/openai_client'

# Minimal Net::HTTP stand-in that records the request and returns a programmable
# response. Used to test request shape + response parsing without spending
# tokens. Mirrors what AnthropicClient assumes from @http (a `.request` method
# that returns an object with `.code` and `.body`).
class FakeHttp
  Response = Struct.new(:code, :body)

  attr_reader :requests

  def initialize(response_code: '200', response_body: '{}')
    @response = Response.new(response_code.to_s, response_body)
    @requests = []
  end

  def request(req)
    @requests << req
    @response
  end
end

class OpenAIClientTest < Minitest::Test
  def test_complete_returns_assistant_text_from_response
    # Given an HTTP fake that returns a typical OpenAI Chat Completions body
    body = JSON.generate(choices: [{ message: { content: 'translated reply' } }])
    fake = FakeHttp.new(response_code: '200', response_body: body)
    client = WooAiTranslation::OpenAIClient.new(api_key: 'sk-test', http: fake)

    # When we call complete
    out = client.complete(messages: [{ role: 'user', content: 'hi' }])

    # Then we get the parsed text content
    assert_equal 'translated reply', out
  end

  def test_complete_sends_bearer_auth_and_json_body
    # Given an HTTP fake that records the outgoing request
    body = JSON.generate(choices: [{ message: { content: 'ok' } }])
    fake = FakeHttp.new(response_code: '200', response_body: body)
    client = WooAiTranslation::OpenAIClient.new(api_key: 'sk-test-12345', http: fake)

    # When we call complete with a specific model + messages
    client.complete(model: 'gpt-5.1', messages: [{ role: 'user', content: 'hi' }])

    # Then exactly one request was sent with the expected headers + body
    assert_equal 1, fake.requests.size
    req = fake.requests.first
    assert_equal 'Bearer sk-test-12345', req['authorization']
    assert_equal 'application/json', req['content-type']
    parsed = JSON.parse(req.body)
    assert_equal 'gpt-5.1', parsed['model']
    assert_equal [{ 'role' => 'user', 'content' => 'hi' }], parsed['messages']
    assert_equal 0, parsed['temperature']
  end

  def test_complete_raises_error_on_non_2xx_response
    # Given an HTTP fake that returns 400
    fake = FakeHttp.new(response_code: '400', response_body: '{"error":"bad input"}')
    client = WooAiTranslation::OpenAIClient.new(api_key: 'sk-test', http: fake)

    # When we call complete
    err = assert_raises(WooAiTranslation::OpenAIClient::Error) do
      client.complete(messages: [{ role: 'user', content: 'hi' }])
    end

    # Then the error message includes the HTTP code + body
    assert_match(/HTTP 400/, err.message)
    assert_match(/bad input/, err.message)
  end

  def test_complete_raises_error_when_api_key_missing
    # Given a client with no API key
    client = WooAiTranslation::OpenAIClient.new(api_key: nil)

    # When we call complete
    err = assert_raises(WooAiTranslation::OpenAIClient::Error) do
      client.complete(messages: [{ role: 'user', content: 'hi' }])
    end

    # Then the error says the key is missing
    assert_match(/OPENAI_API_KEY/, err.message)
  end

  def test_available_returns_true_when_key_present_and_false_when_blank
    # Given a client with a key
    assert WooAiTranslation::OpenAIClient.new(api_key: 'sk-x').available?

    # And a client without a key
    refute WooAiTranslation::OpenAIClient.new(api_key: nil).available?
    refute WooAiTranslation::OpenAIClient.new(api_key: '').available?
  end

  def test_from_env_reads_openai_api_key_env_var
    # Given OPENAI_API_KEY is set
    saved = ENV.fetch('OPENAI_API_KEY', nil)
    ENV['OPENAI_API_KEY'] = 'sk-from-env'
    client = WooAiTranslation::OpenAIClient.from_env

    # When we check availability
    assert client.available?
  ensure
    ENV['OPENAI_API_KEY'] = saved
  end

  def test_stub_openai_client_default_transform_echoes_last_message
    # Given a default-configured stub
    stub = WooAiTranslation::StubOpenAIClient.new

    # When we call complete
    out = stub.complete(messages: [
                          { role: 'system', content: 'system rules' },
                          { role: 'user', content: 'hello there' }
                        ])

    # Then the output echoes (a truncated form of) the user content
    assert_includes out, 'hello there'
    assert_equal 1, stub.calls
  end

  def test_stub_openai_client_accepts_custom_transform
    # Given a stub with a custom transform
    stub = WooAiTranslation::StubOpenAIClient.new { |_messages| 'canned response' }

    # When we call complete
    out = stub.complete(messages: [{ role: 'user', content: 'whatever' }])

    # Then the output is whatever the transform returned
    assert_equal 'canned response', out
  end

  def test_stub_openai_client_counts_calls
    # Given a stub
    stub = WooAiTranslation::StubOpenAIClient.new

    # When we call complete multiple times
    3.times { stub.complete(messages: [{ role: 'user', content: 'x' }]) }

    # Then calls increments
    assert_equal 3, stub.calls
  end
end
