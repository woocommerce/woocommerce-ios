# frozen_string_literal: true

module WooAiTranslation
  # Computes a safe per-batch entry count based on the target locale's script.
  #
  # Why this exists: every translation backend has an output-token cap, and
  # non-Latin scripts (Devanagari, Thai, CJK) cost ~3 bytes/char in UTF-8 vs.
  # ~1 byte/char for Latin. A 1500-entry batch that's fine in French will
  # overflow the cap in Hindi.
  #
  # This module estimates the output token cost per entry given the locale,
  # then picks a batch size that fits the configured budget with headroom.
  #
  # Usage:
  #   sizer = ByteSizer.new(max_output_tokens: 8192)
  #   batch_size = sizer.recommended_batch_size(locale: 'hi')  # => ~120
  #
  # Defaults are intentionally conservative. Callers can override via flags.
  class ByteSizer
    # Bytes per character in UTF-8 by script family.
    SCRIPT_BYTES_PER_CHAR = {
      latin: 1.1,        # mostly 1-byte ASCII, some 2-byte diacritics
      cyrillic: 2.0,     # bg, ru, uk, etc.
      greek: 2.0,        # el
      vietnamese: 1.6,   # vi — Latin base with multi-byte diacritics
      devanagari: 3.0,   # hi
      thai: 3.0,         # th
      cjk: 3.0,          # ja, ko, zh
      hebrew: 2.0,       # he
      arabic: 2.0        # ar
    }.freeze

    LOCALE_SCRIPT = {
      'bg' => :cyrillic, 'ru' => :cyrillic, 'uk' => :cyrillic,
      'el' => :greek,
      'hi' => :devanagari,
      'th' => :thai,
      'ja' => :cjk, 'ko' => :cjk, 'zh' => :cjk, 'zh-Hans' => :cjk, 'zh-Hant' => :cjk,
      'he' => :hebrew,
      'ar' => :arabic,
      'vi' => :vietnamese
    }.freeze

    # Approximate tokens per UTF-8 byte (Anthropic models). Conservative high
    # estimate so we under-budget rather than overflow.
    TOKENS_PER_BYTE = 0.4

    # JSON envelope overhead per entry: {"id":"...","translation":"..."},
    # plus comma + whitespace. Round up.
    JSON_OVERHEAD_BYTES_PER_ENTRY = 40

    # Average English source length per entry in this codebase (sampled from
    # WooCommerce/Resources/en.lproj/Localizable.strings, 5141 entries).
    DEFAULT_SOURCE_BYTES_PER_ENTRY = 60

    # Reserve fraction for prompt-side variability (locale name, system block
    # not counted here since it's in input not output).
    HEADROOM_FRACTION = 0.7

    def initialize(max_output_tokens: 8192,
                   source_bytes_per_entry: DEFAULT_SOURCE_BYTES_PER_ENTRY,
                   headroom: HEADROOM_FRACTION)
      @max_output_tokens = max_output_tokens
      @source_bytes_per_entry = source_bytes_per_entry
      @headroom = headroom
    end

    # Tokens an output entry is estimated to cost for this locale.
    def tokens_per_entry(locale:)
      script = LOCALE_SCRIPT.fetch(locale.to_s, :latin)
      bytes_per_char = SCRIPT_BYTES_PER_CHAR.fetch(script)
      # Output value bytes scale with script density; assume the translated
      # value is the same character count as the source (rough).
      value_bytes = @source_bytes_per_entry * bytes_per_char
      total_bytes = value_bytes + JSON_OVERHEAD_BYTES_PER_ENTRY
      (total_bytes * TOKENS_PER_BYTE).ceil
    end

    # Largest safe batch size for the given locale + budget.
    # Always returns at least 1.
    def recommended_batch_size(locale:)
      budget_tokens = (@max_output_tokens * @headroom).floor
      per_entry = tokens_per_entry(locale: locale)
      [budget_tokens / per_entry, 1].max
    end

    # Script family for the given locale (helpful for diagnostics).
    def script_for(locale:)
      LOCALE_SCRIPT.fetch(locale.to_s, :latin)
    end
  end
end
