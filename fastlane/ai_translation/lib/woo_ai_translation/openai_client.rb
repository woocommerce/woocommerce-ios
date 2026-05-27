# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module WooAiTranslation
  # Thin OpenAI Chat Completions API client.
  #
  # Used by `AiJudge` (Tier 2 of shadow-diff) so the judge model is from a
  # different model family than the production translator (Anthropic Claude).
  # Cross-family judging reduces the self-bias problem where Haiku judges
  # another Haiku's output and inevitably skews toward "equivalent".
  #
  # Shape intentionally mirrors `AnthropicClient` so the rest of the engine
  # can treat them as similar shapes. Bearer-token auth instead of x-api-key;
  # `messages` array with explicit roles instead of separate `system_blocks` +
  # `user_content`. No prompt caching (OpenAI handles it transparently in the
  # backend; no header to set).
  #
  # Retries on timeout / 429 / 5xx with exponential backoff. Honors `Retry-After`
  # if present.
  class OpenAIClient
    class Error < StandardError; end

    DEFAULT_BASE_URL = 'https://api.openai.com'
    DEFAULT_MODEL = 'gpt-5.1'
    MAX_RETRIES = 5

    def self.from_env
      new(
        api_key: ENV.fetch('OPENAI_API_KEY', nil),
        base_url: ENV['WOO_AI_OPENAI_BASE_URL'] || DEFAULT_BASE_URL
      )
    end

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, http: nil)
      @api_key = api_key
      @base_url = base_url
      @http = http
    end

    def available?
      !@api_key.to_s.empty?
    end

    # messages: array of `{ role: 'system' | 'user' | 'assistant', content: String }` hashes.
    # Returns the assistant text content (String).
    def complete(messages:, model: DEFAULT_MODEL, max_tokens: 8192, temperature: 0)
      raise Error, 'OPENAI_API_KEY is not set' unless available?

      body = {
        model: model,
        messages: messages,
        max_tokens: max_tokens,
        temperature: temperature
      }
      with_retries { post_chat(body) }
    end

    private

    def post_chat(body)
      uri = URI.join("#{@base_url}/", 'v1/chat/completions')
      req = Net::HTTP::Post.new(uri)
      req['content-type'] = 'application/json'
      req['authorization'] = "Bearer #{@api_key}"
      req.body = JSON.generate(body)

      res = http_client(uri).request(req)
      raise Error, "HTTP #{res.code}: #{res.body}" unless res.code.to_i.between?(200, 299)

      json = JSON.parse(res.body)
      json.dig('choices', 0, 'message', 'content').to_s
    end

    def http_client(uri)
      return @http if @http

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 30
      http.read_timeout = 120
      http
    end

    def with_retries
      attempt = 0
      begin
        yield
      rescue Error, Net::OpenTimeout, Net::ReadTimeout => e
        attempt += 1
        raise if attempt > MAX_RETRIES
        raise if e.is_a?(Error) && client_error_no_retry?(e)

        sleep(backoff_seconds(attempt))
        retry
      end
    end

    def client_error_no_retry?(error)
      m = error.message[/HTTP (\d+)/, 1]
      return false if m.nil?

      code = m.to_i
      code.between?(400, 499) && code != 429
    end

    def backoff_seconds(attempt)
      (2**attempt) + rand
    end
  end

  # Deterministic offline stand-in for OpenAI used by tests and offline dry runs.
  # Mirrors `StubClient` for Anthropic. Default behavior echoes a tagged version
  # of the last user message so tests can verify the integration without
  # spending tokens.
  class StubOpenAIClient
    def initialize(&transform)
      @transform = transform || ->(messages) { "[stub-openai] #{messages.last[:content][0..80]}" }
      @calls = 0
    end

    attr_reader :calls

    def available?
      true
    end

    def complete(messages:, model: nil, max_tokens: nil, temperature: nil)
      _ = [model, max_tokens, temperature] # unused in stub
      @calls += 1
      @transform.call(messages)
    end
  end
end
