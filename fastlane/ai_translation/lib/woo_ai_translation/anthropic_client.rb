# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

require_relative 'constants'

module WooAiTranslation
  # Thin Anthropic Messages API client.
  #
  # - Key from ENV (never committed). Prefer the Automattic AI gateway by setting
  #   WOO_AI_TRANSLATION_BASE_URL; otherwise the Anthropic API directly.
  # - System blocks are marked with cache_control so the large constant prefix
  #   (rules + per-locale style) is prompt-cached across the thousands of calls;
  #   only the per-batch user message varies.
  # - Retries with exponential backoff on timeouts / 429 / 5xx.
  #
  # Lifted from the woocommerce-android engine (Phase 2 / PR #15962) without
  # changes -- platform-agnostic.
  class AnthropicClient
    class Error < StandardError; end

    DEFAULT_BASE_URL = 'https://api.anthropic.com'
    MAX_RETRIES = 5

    # Plain-HTTP is only tolerated for a local proxy on the loopback interface.
    # Anywhere else it would put the API key on the wire in clear text.
    LOOPBACK_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

    def self.from_env
      new(
        api_key: ENV.fetch('ANTHROPIC_API_KEY', nil),
        base_url: ENV['WOO_AI_TRANSLATION_BASE_URL'] || DEFAULT_BASE_URL
      )
    end

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, http: nil)
      @api_key = api_key
      @base_url = base_url
      @http = http
      # Only guard the real network path; an injected transport (tests) owns
      # its own security posture.
      ensure_secure_base_url!(base_url) if @http.nil?
    end

    def available?
      !@api_key.to_s.empty?
    end

    # system_blocks: array of strings; the last is cache-flagged.
    # Returns the assistant text content (String).
    def complete(model:, system_blocks:, user_content:, max_tokens: 8192)
      raise Error, 'ANTHROPIC_API_KEY is not set' unless available?

      # Older Anthropic models accepted `temperature: 0` for strict
      # determinism, but Haiku 4.5 / Opus 4.7 (our current default +
      # escalation models) reject the parameter with HTTP 400. Rather
      # than maintain a per-model allowlist, we omit it entirely and let
      # the API pick its default. We get mild non-determinism in
      # exchange; the manifest cache deduplicates across runs and the
      # validator catches any meaningful drift on individual entries.
      body = {
        model: model,
        max_tokens: max_tokens,
        system: cacheable_system(system_blocks),
        messages: [{ role: 'user', content: user_content }]
      }
      with_retries { post_messages(body) }
    end

    private

    # Refuse to construct a client that would transmit the API key over an
    # unencrypted connection. https is always fine; plain http only to a
    # loopback host (a local gateway/proxy). Everything else raises.
    def ensure_secure_base_url!(base_url)
      uri = URI.parse(base_url.to_s)
      return if uri.scheme == 'https'
      return if uri.scheme == 'http' && LOOPBACK_HOSTS.include?(uri.hostname.to_s.downcase)

      raise Error, "Refusing to send the API key to #{base_url.inspect} over an insecure connection. " \
                   'Use https://, or http:// only for a loopback host (localhost/127.0.0.1/::1).'
    rescue URI::InvalidURIError => e
      raise Error, "Invalid base URL #{base_url.inspect}: #{e.message}"
    end

    def cacheable_system(blocks)
      blocks.each_with_index.map do |text, i|
        block = { type: 'text', text: text }
        block[:cache_control] = { type: 'ephemeral' } if i == blocks.length - 1
        block
      end
    end

    def post_messages(body)
      uri = URI.join("#{@base_url}/", 'v1/messages')
      req = Net::HTTP::Post.new(uri)
      req['content-type'] = 'application/json'
      req['x-api-key'] = @api_key
      req['anthropic-version'] = ANTHROPIC_VERSION
      req['anthropic-beta'] = 'prompt-caching-2024-07-31'
      req.body = JSON.generate(body)

      res = http_client(uri).request(req)
      raise Error, "HTTP #{res.code}: #{res.body}" unless res.code.to_i.between?(200, 299)

      json = JSON.parse(res.body)
      Array(json['content']).map { |c| c['text'] }.compact.join
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

  # Deterministic offline stand-in used by tests and `--offline` dry runs.
  # Echoes a locale-tagged source so the pipeline (parse, batch, write) is
  # exercised without network or spend.
  class StubClient
    def initialize(&transform)
      @transform = transform || ->(loc, src) { "[#{loc}] #{src}" }
      @calls = 0
    end

    attr_reader :calls

    def available?
      true
    end

    def complete(model:, system_blocks:, user_content:, max_tokens: 8192)
      _ = [model, system_blocks, max_tokens] # unused in stub
      @calls += 1
      locale = user_content[/locale:\s*([\w-]+)/, 1] || '??'
      payload = JSON.parse(user_content[/\[.*\]/m] || '[]')
      out = payload.to_h { |item| [item['id'], @transform.call(locale, item['source'])] }
      JSON.generate(out)
    end
  end
end
