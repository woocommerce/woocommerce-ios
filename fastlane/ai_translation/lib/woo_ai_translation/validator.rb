# frozen_string_literal: true

require 'yaml'

module WooAiTranslation
  # Translation validator. Loads glossary YAMLs and applies two hard rules
  # per translated entry:
  #
  #   1. Brand-safety: every brand name from `glossary/common.yml` that
  #      appears in the source MUST appear unchanged in the translation.
  #
  #   2. Glossary lookup: if the source text equals a key in the per-locale
  #      glossary's `ui_terms` or `nouns` section, the translation MUST
  #      equal the mapped value.
  #
  # Returns a list of violation hashes; an empty list means the translation
  # is acceptable. Callers (the translator pipeline) decide whether to retry
  # or reject the entry.
  #
  # The validator never mutates the translation. It only reports.
  class Validator
    GlossaryPaths = Struct.new(:common, :locale, keyword_init: true)

    class << self
      # Load brand list + a single locale's glossary.
      # base_dir is the directory containing `common.yml` and `<locale>.yml`.
      def for_locale(locale:, base_dir:)
        common_path = File.join(base_dir, 'common.yml')
        locale_path = File.join(base_dir, "#{locale}.yml")
        new(
          locale: locale,
          common: load_yaml(common_path),
          locale_glossary: load_yaml(locale_path)
        )
      end

      def load_yaml(path)
        return {} unless File.exist?(path)

        YAML.safe_load_file(path) || {}
      end
    end

    attr_reader :locale, :brands, :terms

    def initialize(locale:, common:, locale_glossary:)
      @locale = locale
      @brands = collect_brands(common)
      @terms = collect_terms(locale_glossary)
    end

    # Validate one (source, translation) pair.
    # Returns an array of violation hashes; empty array means OK.
    #
    # A violation hash has:
    #   - :rule (:brand_safety | :glossary)
    #   - :term (the offending term)
    #   - :expected (the expected translation, for glossary rule)
    def validate(source:, translation:)
      violations = []
      violations.concat(brand_violations(source, translation))
      violations.concat(glossary_violations(source, translation))
      violations
    end

    private

    def collect_brands(common)
      vals = []
      (common || {}).each_value { |list| vals.concat(Array(list)) }
      vals.compact.map(&:to_s).uniq
    end

    def collect_terms(glossary)
      h = {}
      %w[ui_terms nouns].each do |section|
        (glossary[section] || {}).each { |k, v| h[k.to_s] = v.to_s }
      end
      h
    end

    # Brand-safety check with "longest match wins": when WooCommerce appears
    # in the source, we don't also flag Woo (which is a substring of it).
    # We sort brands by length descending and mask each found occurrence so
    # subsequent (shorter) brand checks don't double-count it.
    def brand_violations(source, translation)
      src = source.to_s.dup
      tx = translation.to_s
      sorted = @brands.sort_by { |b| -b.length }

      violations = []
      sorted.each do |brand|
        next unless src.include?(brand)

        # Mask this brand in the working copy so shorter brands that are
        # substrings won't trigger.
        src.gsub!(brand, "\u0001" * brand.length)
        next if tx.include?(brand)

        violations << { rule: :brand_safety, term: brand, expected: brand }
      end
      violations
    end

    # The glossary rule fires only when the source EQUALS a glossary key
    # (case-insensitive, trimmed). This is intentionally narrow: short UI
    # labels like "Cancel" or "Orders" should always map to the canonical
    # term, but free-form sentences that happen to contain "orders" as a
    # substring are not constrained.
    def glossary_violations(source, translation)
      key = source.to_s.strip
      lookup = @terms.find { |term, _| term.downcase == key.downcase }
      return [] unless lookup

      expected = lookup.last
      return [] if translation.to_s.strip == expected

      [{ rule: :glossary, term: lookup.first, expected: expected }]
    end
  end
end
