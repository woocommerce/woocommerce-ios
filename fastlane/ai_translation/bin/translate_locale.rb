#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal one-shot translator for the iOS pilot.
#
# Reads WooCommerce/Resources/en.lproj/Localizable.strings (+ InfoPlist.strings)
# and writes WooCommerce/Resources/<locale>.lproj/* with AI-translated values.
#
# No Fastlane, no manifest. Skip the engine port for the pilot; reuse only
# IosResources + Translator + AnthropicClient.
#
# Usage:
#   ANTHROPIC_API_KEY=sk-... ruby fastlane/ai_translation/bin/translate_locale.rb pl
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --offline   # stub, no API call
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --batch 30
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --skip-infoplist
#
# Outputs:
#   WooCommerce/Resources/<locale>.lproj/Localizable.strings
#   WooCommerce/Resources/<locale>.lproj/InfoPlist.strings  (unless --skip-infoplist)
#   /tmp/translate_locale_<locale>.log

require 'optparse'
require 'time'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'woo_ai_translation/constants'
require 'woo_ai_translation/ios_resources'
require 'woo_ai_translation/anthropic_client'
require 'woo_ai_translation/translator'
require 'woo_ai_translation/byte_sizer'

REPO_ROOT = File.expand_path('../../..', __dir__)
SOURCE_DIR = File.join(REPO_ROOT, 'WooCommerce/Resources/en.lproj')
TARGET_BASE = File.join(REPO_ROOT, 'WooCommerce/Resources')

# Locale-name table used in the prompt's per-locale style block. Same list the
# Android engine ships; expand if/when we add more.
LOCALE_NAMES = {
  'pl' => 'Polish (pl-PL)',
  'cs' => 'Czech (cs-CZ)',
  'da' => 'Danish (da-DK)',
  'nb' => 'Norwegian Bokmål (nb-NO)',
  'fi' => 'Finnish (fi-FI)',
  'el' => 'Greek (el-GR)',
  'hu' => 'Hungarian (hu-HU)',
  'ro' => 'Romanian (ro-RO)',
  'uk' => 'Ukrainian (uk-UA)',
  'bg' => 'Bulgarian (bg-BG)',
  'th' => 'Thai (th-TH)',
  'vi' => 'Vietnamese (vi-VN)',
  'hi' => 'Hindi (hi-IN)',
  'ms' => 'Malay (ms-MY)',
  'pt-PT' => 'European Portuguese (pt-PT)'
}.freeze

# Capture placeholder tokens of any kind iOS uses. Order-sensitive comparison
# is done by counting occurrences per token, so reordering is tolerated but
# missing / extra placeholders are rejected.
PLACEHOLDER_RE = /
  %                              # leading %
  (?:\d+\$)?                     # optional positional index (1$, 2$, ...)
  [\#\-+0\ ]?                    # optional flag
  (?:\d+|\*)?                    # optional width
  (?:\.\d+)?                     # optional precision
  (?:hh|h|ll|l|q|L|z|j|t)?       # optional length modifier
  [@dDuUxXoOfeEgGcCsSpaAi%]      # conversion specifier (incl. iOS %@)
/x

def parse_args(argv)
  opts = {
    locale: nil,
    offline: false,
    batch: nil, # nil => auto-size via ByteSizer
    skip_infoplist: false,
    limit: nil,
    model: WooAiTranslation::DEFAULT_MODEL,
    incremental: false,
    max_output_tokens: 8192
  }
  parser = OptionParser.new do |p|
    p.banner = 'Usage: translate_locale.rb <locale> [options]'
    p.on('--offline', 'Use StubClient (no API call, deterministic)') { opts[:offline] = true }
    p.on('--batch N', Integer, 'Override auto-sized batch (default: ByteSizer)') { |v| opts[:batch] = v }
    p.on('--limit N', Integer, 'Translate only the first N keys (smoke test)') { |v| opts[:limit] = v }
    p.on('--skip-infoplist', 'Skip InfoPlist.strings') { opts[:skip_infoplist] = true }
    p.on('--model NAME', "Override model (default: #{opts[:model]})") { |v| opts[:model] = v }
    p.on('--incremental', 'Only translate keys missing in the target locale (PR-time mode)') { opts[:incremental] = true }
    p.on('--max-output-tokens N', Integer, "Output budget for auto batch sizing (default: #{opts[:max_output_tokens]})") { |v| opts[:max_output_tokens] = v }
  end
  parser.permute!(argv)
  opts[:locale] = argv.shift or abort(parser.help)
  abort("unknown locale '#{opts[:locale]}' (expand LOCALE_NAMES in the script)") unless LOCALE_NAMES.key?(opts[:locale])
  opts
end

# Returns the subset of EN units that are missing from (or empty in) the
# target locale file. Used by --incremental mode.
def filter_missing_units(en_units, target_path, logger:)
  return en_units unless File.exist?(target_path)

  existing = WooAiTranslation::IosResources::Parser.parse_file(target_path)
  existing_by_name = existing.units.to_h { |u| [u.name, u] }

  en_units.reject do |u|
    existing_unit = existing_by_name[u.name]
    next false unless existing_unit

    existing_value = existing_unit.entries.first[:value].to_s
    en_value = u.entries.first[:source].to_s
    !existing_value.empty? && existing_value != en_value
  end.tap do |missing|
    logger.call("[--incremental] #{en_units.size} EN keys, #{missing.size} need translation (others present)")
  end
end

def placeholder_counts(text)
  text.to_s.scan(PLACEHOLDER_RE).each_with_object(Hash.new(0)) { |t, h| h[t] += 1 }
end

def placeholders_match?(source, translation)
  placeholder_counts(source) == placeholder_counts(translation)
end

def translate_file(input_path:, output_path:, translator:, locale:, model:, limit:, logger:, incremental: false)
  doc = WooAiTranslation::IosResources::Parser.parse_file(input_path)
  units = doc.translatable_units
  units = units.first(limit) if limit
  logger.call("[#{locale}] parsed #{units.size} keys from #{File.basename(input_path)}")

  # Incremental: skip keys already translated in the target file.
  units_to_translate = incremental ? filter_missing_units(units, output_path, logger: logger) : units

  if units_to_translate.empty?
    logger.call("[#{locale}] nothing to translate; output left unchanged")
    return [0, [], []]
  end

  items = units_to_translate.map do |u|
    { id: u.name, source: u.entries.first[:source], context: u.comment }
  end

  results = translator.translate(locale: locale, items: items, model: model)
  logger.call("[#{locale}] translator returned #{results.size} translations")

  translated = 0
  failed_missing = []
  failed_validation = []

  # In incremental mode we preserve existing values for unchanged keys by
  # starting from the existing target document and only overlaying the new
  # translations. In bootstrap mode we use the EN-derived units (with empty
  # values) as the starting set.
  units_for_write = incremental && File.exist?(output_path) ? merge_with_existing(units, output_path) : units
  by_name = units_for_write.to_h { |u| [u.name, u] }

  units_to_translate.each do |u|
    src = u.entries.first[:source]
    tx = results[u.name]
    if tx.nil? || tx.to_s.empty?
      failed_missing << u.name
      next
    end
    unless placeholders_match?(src, tx)
      failed_validation << { name: u.name, source: src, translation: tx,
                             expected: placeholder_counts(src),
                             got: placeholder_counts(tx) }
      next
    end
    target_unit = by_name[u.name] or next
    target_unit.entries.first[:value] = tx
    translated += 1
  end

  WooAiTranslation::IosResources::Writer.write(output_path, units_for_write, locale)
  logger.call("[#{locale}] wrote #{output_path} (#{translated} keys, " \
              "#{failed_missing.size} missing, #{failed_validation.size} placeholder errors)")
  [translated, failed_missing, failed_validation]
end

# Reload current target doc and project the existing values onto a fresh
# copy of the EN-derived units. Used by --incremental so unchanged keys keep
# their previously-translated value.
def merge_with_existing(en_units, target_path)
  existing = WooAiTranslation::IosResources::Parser.parse_file(target_path)
  existing_by_name = existing.units.to_h { |u| [u.name, u] }
  en_units.each do |u|
    next unless (e = existing_by_name[u.name])

    existing_val = e.entries.first[:value].to_s
    u.entries.first[:value] = existing_val unless existing_val.empty?
  end
  en_units
end

def main(argv)
  opts = parse_args(argv)
  locale = opts[:locale]
  log_path = "/tmp/translate_locale_#{locale}.log"
  log_io = File.open(log_path, 'w')
  logger = lambda do |msg|
    line = "[#{Time.now.utc.iso8601}] #{msg}"
    warn(line)
    log_io.puts(line)
    log_io.flush
  end

  logger.call("start locale=#{locale} model=#{opts[:model]} batch=#{opts[:batch]} " \
              "offline=#{opts[:offline]} limit=#{opts[:limit] || '∞'}")

  client = opts[:offline] ? WooAiTranslation::StubClient.new : WooAiTranslation::AnthropicClient.from_env
  unless client.available?
    logger.call('ANTHROPIC_API_KEY is not set; use --offline for a dry run')
    exit 1
  end

  # Auto-size the batch when not explicitly overridden, so non-Latin scripts
  # don't overflow the output token budget.
  batch_size = opts[:batch] || begin
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: opts[:max_output_tokens])
    auto = sizer.recommended_batch_size(locale: locale)
    logger.call("batch auto-sized to #{auto} for #{locale} (#{sizer.script_for(locale: locale)})")
    auto
  end

  translator = WooAiTranslation::Translator.new(
    client: client,
    batch_size: batch_size,
    logger: logger
  )

  out_dir = File.join(TARGET_BASE, "#{locale}.lproj")

  # --- Localizable.strings (the main corpus) ----------------------------
  t0 = Time.now
  trans, missing, errors = translate_file(
    input_path: File.join(SOURCE_DIR, 'Localizable.strings'),
    output_path: File.join(out_dir, 'Localizable.strings'),
    translator: translator, locale: locale, model: opts[:model],
    limit: opts[:limit], logger: logger, incremental: opts[:incremental]
  )
  logger.call("Localizable.strings done in #{(Time.now - t0).round(1)}s")
  total_translated = trans
  all_missing = missing
  all_errors = errors

  # --- InfoPlist.strings (16 entries, small but important) --------------
  unless opts[:skip_infoplist]
    t0 = Time.now
    info_in = File.join(SOURCE_DIR, 'InfoPlist.strings')
    info_out = File.join(out_dir, 'InfoPlist.strings')
    if File.exist?(info_in)
      trans, missing, errors = translate_file(
        input_path: info_in, output_path: info_out,
        translator: translator, locale: locale, model: opts[:model],
        limit: nil, logger: logger, incremental: opts[:incremental]
      )
      logger.call("InfoPlist.strings done in #{(Time.now - t0).round(1)}s")
      total_translated += trans
      all_missing.concat(missing)
      all_errors.concat(errors)
    else
      logger.call("no InfoPlist.strings at #{info_in}; skipping")
    end
  end

  # --- Summary ----------------------------------------------------------
  logger.call('===== summary =====')
  logger.call("locale=#{locale} translated=#{total_translated} missing=#{all_missing.size} " \
              "placeholder_errors=#{all_errors.size}")
  unless all_errors.empty?
    logger.call('---- placeholder errors (first 10) ----')
    all_errors.first(10).each do |e|
      logger.call("  #{e[:name]}: src=#{e[:source].inspect} tx=#{e[:translation].inspect}")
      logger.call("    expected=#{e[:expected]} got=#{e[:got]}")
    end
  end
  unless all_missing.empty?
    logger.call('---- missing translations (first 10) ----')
    all_missing.first(10).each { |n| logger.call("  #{n}") }
  end

  logger.call("log written to #{log_path}")
  log_io.close
  exit(all_errors.empty? && all_missing.empty? ? 0 : 2)
end

main(ARGV) if $PROGRAM_NAME == __FILE__
