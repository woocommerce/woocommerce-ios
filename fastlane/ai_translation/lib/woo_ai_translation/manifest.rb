# frozen_string_literal: true

require 'json'
require 'digest'
require 'fileutils'
require 'time'

require_relative 'constants'

module WooAiTranslation
  # Per-locale translation manifest. Persisted as JSON at
  # `fastlane/ai_translation/manifest/<locale>.json`.
  #
  # The manifest records, per source key:
  #   - src_sha    : sha256(source) truncated to 12 chars. The source-only
  #                  invalidation signal: re-translate only when the EN
  #                  source value changes.
  #   - model      : the model that produced the translation.
  #   - pv         : prompt-version tag at the time of translation.
  #   - origin     : free-form provenance tag (e.g. "bootstrap-2026-05-21",
  #                  "ai", "ai-opus-retry", "human-glotpress").
  #   - at         : ISO-8601 UTC timestamp.
  #
  # This matches the contract described in Jorge's iOS/Android alignment
  # report and the Android `manifest.rb`. Designed for diffability: keys
  # are sorted, two-space indent, stable formatting.
  #
  # Invariants:
  #   - Loading a nonexistent file is OK and yields an empty manifest.
  #   - `needs_translation?` returns true when no entry exists, or when
  #     `src_sha` differs from the entry's recorded `src_sha`.
  #   - Model/prompt-version bumps do NOT auto-invalidate. Callers that
  #     want to re-translate everything pass `--force` (not handled here;
  #     the CLI should branch on its own flag).
  class Manifest
    SCHEMA_VERSION = 1

    attr_reader :locale, :path

    def self.path_for(locale:, base_dir: nil)
      base = base_dir || File.expand_path('../../manifest', __dir__)
      File.join(base, "#{locale}.json")
    end

    def initialize(locale:, path: nil, base_dir: nil)
      @locale = locale
      @path = path || self.class.path_for(locale: locale, base_dir: base_dir)
      @data = load_data
    end

    def needs_translation?(key:, source:)
      entry = @data['entries'][key.to_s]
      return true unless entry

      entry['src_sha'] != self.class.src_sha(source)
    end

    def record!(key:, source:, model: nil, origin: 'ai', prompt_version: nil)
      @data['entries'][key.to_s] = {
        'src_sha' => self.class.src_sha(source),
        'model' => model || WooAiTranslation::DEFAULT_MODEL,
        'pv' => prompt_version || WooAiTranslation::PROMPT_VERSION,
        'origin' => origin,
        'at' => Time.now.utc.iso8601
      }
    end

    def entry(key)
      @data['entries'][key.to_s]
    end

    def size
      @data['entries'].size
    end

    def save!
      FileUtils.mkdir_p(File.dirname(@path))
      sorted = @data.dup
      sorted['entries'] = @data['entries'].sort.to_h
      File.write(@path, "#{JSON.pretty_generate(sorted)}\n")
    end

    def self.src_sha(value)
      Digest::SHA256.hexdigest(value.to_s)[0, 12]
    end

    private

    def load_data
      if File.exist?(@path)
        parsed = JSON.parse(File.read(@path))
        # Schema migration / sanity: keep the structure shape stable even if
        # an older file is read.
        parsed['entries'] ||= {}
        parsed['locale'] ||= @locale
        parsed['schema_version'] ||= SCHEMA_VERSION
        parsed
      else
        {
          'locale' => @locale,
          'schema_version' => SCHEMA_VERSION,
          'engine_version' => WooAiTranslation::VERSION,
          'entries' => {}
        }
      end
    end
  end
end
