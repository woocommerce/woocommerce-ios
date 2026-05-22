#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI translator for the iOS localization engine.
#
# Reads WooCommerce/Resources/en.lproj/Localizable.strings (+ InfoPlist.strings)
# and writes WooCommerce/Resources/<locale>.lproj/* with AI-translated values.
#
# Supports full bootstrap and --incremental (manifest-backed, source-only
# invalidation) modes. Run directly or via the Rake tasks in this directory.
#
# Usage:
#   ANTHROPIC_API_KEY=sk-... ruby fastlane/ai_translation/bin/translate_locale.rb pl
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --offline      # stub, no API call
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --incremental  # only missing keys
#   ruby fastlane/ai_translation/bin/translate_locale.rb pl --limit 5      # smoke test, not written
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
require 'woo_ai_translation/manifest'
require 'woo_ai_translation/validator'

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
    escalation_model: WooAiTranslation::ESCALATION_MODEL,
    incremental: false,
    max_output_tokens: 8192,
    use_manifest: true,
    use_escalation: true
  }
  parser = OptionParser.new do |p|
    p.banner = 'Usage: translate_locale.rb <locale> [options]'
    p.on('--offline', 'Use StubClient (no API call, deterministic)') { opts[:offline] = true }
    p.on('--batch N', Integer, 'Override auto-sized batch (default: ByteSizer)') { |v| opts[:batch] = v }
    p.on('--limit N', Integer, 'Translate only the first N keys (smoke test)') { |v| opts[:limit] = v }
    p.on('--skip-infoplist', 'Skip InfoPlist.strings') { opts[:skip_infoplist] = true }
    p.on('--model NAME', "Override model (default: #{opts[:model]})") { |v| opts[:model] = v }
    p.on('--escalation-model NAME', "Retry failed entries with this model (default: #{opts[:escalation_model]})") { |v| opts[:escalation_model] = v }
    p.on('--no-escalation', 'Disable Opus fallback on validator failures') { opts[:use_escalation] = false }
    p.on('--incremental', 'Only translate keys missing in the target locale (PR-time mode)') { opts[:incremental] = true }
    p.on('--no-manifest', 'Bypass the source-only manifest cache') { opts[:use_manifest] = false }
    p.on('--max-output-tokens N', Integer, "Output budget for auto batch sizing (default: #{opts[:max_output_tokens]})") { |v| opts[:max_output_tokens] = v }
  end
  parser.permute!(argv)
  opts[:locale] = argv.shift or abort(parser.help)
  abort("unknown locale '#{opts[:locale]}' (expand LOCALE_NAMES in the script)") unless LOCALE_NAMES.key?(opts[:locale])
  opts
end

# Returns the subset of EN units that need translation.
#
# When a manifest is provided, source-only invalidation drives the decision:
# an entry needs translation iff its source value differs from the recorded
# `src_sha`. Falls back to the heuristic check ("present in target with a
# non-EN value") when no manifest entry exists, which lets us bootstrap a
# manifest from the existing locale files in PR #17220.
def filter_missing_units(en_units, target_path, logger:, manifest: nil)
  existing_by_name = if File.exist?(target_path)
                       WooAiTranslation::IosResources::Parser.parse_file(target_path)
                                                             .units.to_h { |u| [u.name, u] }
                     else
                       {}
                     end

  needs = en_units.reject do |u|
    src = u.entries.first[:source].to_s
    if manifest&.entry(u.name)
      # Source-only manifest invalidation — the canonical path going forward.
      !manifest.needs_translation?(key: u.name, source: src)
    else
      existing_unit = existing_by_name[u.name]
      next false unless existing_unit

      # The parser is file-role agnostic: it stores every parsed string in
      # [:source] and leaves [:value] nil. A parsed *target* unit therefore
      # carries its translation in [:source], so read that — reading [:value]
      # here always sees "" and re-translates the entire locale.
      existing_value = existing_unit.entries.first[:source].to_s
      !existing_value.empty? && existing_value != src
    end
  end

  logger.call("[--incremental] #{en_units.size} EN keys, #{needs.size} need translation " \
              "(manifest=#{manifest ? manifest.size : 'off'})")
  needs
end

def placeholder_counts(text)
  text.to_s.scan(PLACEHOLDER_RE).each_with_object(Hash.new(0)) { |t, h| h[t] += 1 }
end

def placeholders_match?(source, translation)
  placeholder_counts(source) == placeholder_counts(translation)
end

def translate_file(input_path:, output_path:, translator:, locale:, model:, limit:, logger:,
                   incremental: false, manifest: nil, escalation_model: nil, validator: nil,
                   smoke_run: !limit.nil?)
  doc = WooAiTranslation::IosResources::Parser.parse_file(input_path)
  all_units = doc.translatable_units
  # Build the Set via Set.new (not Array#to_set): referencing the Set constant
  # triggers Ruby 3.2's `autoload :Set`, whereas `to_set` alone does not — so on
  # a minimal load path (CI) `to_set` raises NoMethodError. This is also why
  # RuboCop treats an explicit `require 'set'` as redundant.
  expected_names = Set.new(all_units.map(&:name))

  # A smoke run never overwrites the committed locale or records the manifest; it
  # only verifies the render round-trips, then discards the output so nothing
  # claims keys we never wrote. It defaults to "any --limit run", but is threaded
  # explicitly so a no-limit pass that belongs to a smoke run (e.g. the InfoPlist
  # pass invoked with limit: nil while the overall run is --limit) is also smoke
  # and likewise writes nothing.
  record_manifest = smoke_run ? nil : manifest
  units = limit ? all_units.first(limit) : all_units
  smoke_note = smoke_run ? " (smoke run, translating #{units.size})" : ''
  logger.call("[#{locale}] parsed #{all_units.size} keys from #{File.basename(input_path)}#{smoke_note}")

  units_to_translate = incremental ? filter_missing_units(units, output_path, logger: logger, manifest: manifest) : units

  if units_to_translate.empty?
    logger.call("[#{locale}] nothing to translate; output left unchanged")
    # Four-value shape mirrors the success path so callers can always destructure
    # [translated, missing, placeholder_errors, glossary_errors] safely.
    return [0, [], [], []]
  end

  results = run_translation(translator, locale, units_to_translate, model)
  logger.call("[#{locale}] primary pass returned #{results.size} translations (model=#{model})")

  # In incremental mode we preserve existing values for unchanged keys by
  # starting from the existing target document and only overlaying the new
  # translations. In bootstrap mode we use the EN-derived units (with empty
  # values) as the starting set.
  units_for_write = incremental && File.exist?(output_path) ? merge_with_existing(units, output_path) : units
  by_name = units_for_write.to_h { |u| [u.name, u] }

  translated, failed_missing, failed_validation, failed_glossary = apply_results(
    units_to_translate, results, by_name,
    manifest: record_manifest, model: model, origin: 'ai', validator: validator
  )

  # Opus fallback: retry validator-failed entries (placeholder OR glossary)
  # with the escalation model. Successful retries are recorded with
  # origin=ai-opus-retry so the audit trail shows why a stronger model
  # produced the value.
  if escalation_model && !(failed_validation.empty? && failed_glossary.empty?)
    # Set.new (not Array#to_set): referencing the Set constant triggers Ruby 3.2's
    # `autoload :Set`, whereas `to_set` alone raises NoMethodError on a minimal
    # load path (CI). Same reason RuboCop flags an explicit `require 'set'`.
    retry_names = Set.new((failed_validation + failed_glossary).map { |f| f[:name] })
    retry_units = units_to_translate.select { |u| retry_names.include?(u.name) }
    logger.call("[#{locale}] escalating #{retry_units.size} failed entries to #{escalation_model}")
    retry_results = run_translation(translator, locale, retry_units, escalation_model)
    extra_translated, _retry_missing, still_failing_v, still_failing_g = apply_results(
      retry_units, retry_results, by_name,
      manifest: record_manifest, model: escalation_model, origin: 'ai-opus-retry', validator: validator
    )
    translated += extra_translated
    failed_validation = still_failing_v
    failed_glossary = still_failing_g
    logger.call("[#{locale}] escalation recovered #{extra_translated} entries; " \
                "#{still_failing_v.size} placeholder + #{still_failing_g.size} glossary still failing")
  end

  wrote = write_translations!(
    output_path: output_path, units_for_write: units_for_write,
    expected_names: expected_names, locale: locale, logger: logger, smoke_run: smoke_run
  )
  manifest&.save! if wrote

  logger.call("[#{locale}] #{wrote ? 'wrote' : 'verified (smoke, not written)'} #{output_path} " \
              "(#{translated} keys, #{failed_missing.size} missing, " \
              "#{failed_validation.size} placeholder errors, " \
              "#{failed_glossary.size} glossary/brand violations)")
  [translated, failed_missing, failed_validation, failed_glossary]
end

# Install `units_for_write` at `output_path` without ever leaving a corrupt or
# truncated locale behind:
#   1. Render to a sibling temp file.
#   2. Round-trip parse it (catches writer/parser mismatches before install).
#   3. Refuse to install anything missing keys the EN source still has
#      (`expected_names`); this is the guardrail that stops a partial pass from
#      clobbering a complete locale.
#   4. Atomically rename the temp file into place.
#
# Smoke runs (`--limit`) translate only a subset, so they would always trip the
# shrink guard. They verify the temp render, then discard it and return false so
# the caller skips persisting the manifest. Returns true iff the file was
# installed.
def write_translations!(output_path:, units_for_write:, expected_names:, locale:, logger:, smoke_run:)
  tmp_path = "#{output_path}.tmp.#{Process.pid}"
  WooAiTranslation::IosResources::Writer.write(tmp_path, units_for_write, locale)
  verify_round_trip!(tmp_path, units_for_write, logger: logger, locale: locale)

  if smoke_run
    logger.call("[#{locale}] smoke run: verified #{units_for_write.size} keys in temp output; " \
                "leaving #{output_path} unchanged")
    return false
  end

  missing = expected_names - Set.new(units_for_write.map(&:name))
  unless missing.empty?
    raise(
      "Refusing to write #{output_path} for #{locale}: would drop #{missing.size} source keys " \
      "(e.g. #{missing.first(5).to_a.inspect}). Aborting to avoid clobbering the locale."
    )
  end

  File.rename(tmp_path, output_path)
  true
ensure
  File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
end

def run_translation(translator, locale, units, model)
  items = units.map { |u| { id: u.name, source: u.entries.first[:source], context: u.comment } }
  translator.translate(locale: locale, items: items, model: model)
end

# Walk units_to_translate, apply each result, and report counts. Mutates
# the corresponding entries inside `by_name` so the caller can write them.
def apply_results(units_to_translate, results, by_name, manifest:, model:, origin:, validator: nil)
  translated = 0
  failed_missing = []
  failed_validation = []
  failed_glossary = []

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

    if validator
      glossary_violations = validator.validate(source: src, translation: tx)
      unless glossary_violations.empty?
        failed_glossary << { name: u.name, source: src, translation: tx,
                             violations: glossary_violations }
        next
      end
    end

    target_unit = by_name[u.name] or next
    target_unit.entries.first[:value] = tx
    manifest&.record!(key: u.name, source: src, model: model, origin: origin)
    translated += 1
  end

  [translated, failed_missing, failed_validation, failed_glossary]
end

# Write-then-parse sanity check: re-read the file we just wrote and make sure
# the parser sees the same unit names. Catches cases where the writer emits
# output the parser cannot consume (escape mismatches, lost terminators).
def verify_round_trip!(output_path, units_for_write, logger:, locale:)
  reparsed = WooAiTranslation::IosResources::Parser.parse_file(output_path)
  # Set.new rather than Array#to_set so the Set constant reference triggers the
  # Ruby 3.2 autoload (to_set alone does not load 'set' on a minimal load path).
  written = Set.new(units_for_write.map(&:name))
  reread = Set.new(reparsed.units.map(&:name))
  missing = written - reread
  extra = reread - written
  return if missing.empty? && extra.empty?

  raise(
    "Round-trip failure for #{locale} at #{output_path}: " \
    "missing #{missing.size} (#{missing.first(5).to_a.inspect}), " \
    "extra #{extra.size} (#{extra.first(5).to_a.inspect})"
  )
rescue StandardError => e
  logger.call("[#{locale}] ROUND-TRIP FAILED: #{e.message}")
  raise
end

# Reload current target doc and project the existing values onto a fresh
# copy of the EN-derived units. Used by --incremental so unchanged keys keep
# their previously-translated value.
def merge_with_existing(en_units, target_path)
  existing = WooAiTranslation::IosResources::Parser.parse_file(target_path)
  existing_by_name = existing.units.to_h { |u| [u.name, u] }
  en_units.each do |u|
    next unless (e = existing_by_name[u.name])

    # Parsed target units keep their translation in [:source] (the parser
    # leaves [:value] nil regardless of file role), so read [:source] — reading
    # [:value] here would project "" onto every key and drop the locale.
    existing_val = e.entries.first[:source].to_s
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

  manifest = opts[:use_manifest] ? WooAiTranslation::Manifest.new(locale: locale) : nil
  logger.call("manifest #{manifest ? "loaded (#{manifest.size} entries, #{manifest.path})" : 'disabled'}")
  escalation_model = opts[:use_escalation] ? opts[:escalation_model] : nil

  # Load glossary / brand-safety validator if files exist for this locale.
  validator = begin
    base = File.expand_path('../glossary', __dir__)
    WooAiTranslation::Validator.for_locale(locale: locale, base_dir: base) if Dir.exist?(base)
  end
  logger.call("validator loaded: brands=#{validator&.brands&.size || 0} terms=#{validator&.terms&.size || 0}") if validator

  out_dir = File.join(TARGET_BASE, "#{locale}.lproj")

  # A --limit run is a smoke test of the whole locale, not just the first file.
  # Thread it through every pass — including the no-limit InfoPlist pass below —
  # so a smoke run writes nothing and never persists the manifest.
  smoke_run = !opts[:limit].nil?

  # --- Localizable.strings (the main corpus) ----------------------------
  t0 = Time.now
  trans, missing, errors, glossary_errors = translate_file(
    input_path: File.join(SOURCE_DIR, 'Localizable.strings'),
    output_path: File.join(out_dir, 'Localizable.strings'),
    translator: translator, locale: locale, model: opts[:model],
    limit: opts[:limit], logger: logger, incremental: opts[:incremental],
    manifest: manifest, escalation_model: escalation_model,
    validator: validator, smoke_run: smoke_run
  )
  logger.call("Localizable.strings done in #{(Time.now - t0).round(1)}s")
  total_translated = trans
  all_missing = missing
  all_errors = errors
  all_glossary_errors = glossary_errors

  # --- InfoPlist.strings (16 entries, small but important) --------------
  unless opts[:skip_infoplist]
    t0 = Time.now
    info_in = File.join(SOURCE_DIR, 'InfoPlist.strings')
    info_out = File.join(out_dir, 'InfoPlist.strings')
    if File.exist?(info_in)
      trans, missing, errors, glossary_errors = translate_file(
        input_path: info_in, output_path: info_out,
        translator: translator, locale: locale, model: opts[:model],
        limit: nil, logger: logger, incremental: opts[:incremental],
        manifest: manifest, escalation_model: escalation_model,
        validator: validator, smoke_run: smoke_run
      )
      logger.call("InfoPlist.strings done in #{(Time.now - t0).round(1)}s")
      total_translated += trans
      all_missing.concat(missing)
      all_errors.concat(errors)
      all_glossary_errors.concat(glossary_errors)
    else
      logger.call("no InfoPlist.strings at #{info_in}; skipping")
    end
  end

  # --- Summary ----------------------------------------------------------
  logger.call('===== summary =====')
  logger.call("locale=#{locale} translated=#{total_translated} missing=#{all_missing.size} " \
              "placeholder_errors=#{all_errors.size} glossary_violations=#{all_glossary_errors.size}")
  unless all_errors.empty?
    logger.call('---- placeholder errors (first 10) ----')
    all_errors.first(10).each do |e|
      logger.call("  #{e[:name]}: src=#{e[:source].inspect} tx=#{e[:translation].inspect}")
      logger.call("    expected=#{e[:expected]} got=#{e[:got]}")
    end
  end
  unless all_glossary_errors.empty?
    logger.call('---- glossary/brand violations (first 10) ----')
    all_glossary_errors.first(10).each do |e|
      logger.call("  #{e[:name]}: src=#{e[:source].inspect} tx=#{e[:translation].inspect}")
      e[:violations].each { |v| logger.call("    #{v[:rule]}: term=#{v[:term].inspect} expected=#{v[:expected].inspect}") }
    end
  end
  unless all_missing.empty?
    logger.call('---- missing translations (first 10) ----')
    all_missing.first(10).each { |n| logger.call("  #{n}") }
  end

  logger.call("log written to #{log_path}")
  log_io.close
  exit_code = all_errors.empty? && all_missing.empty? && all_glossary_errors.empty? ? 0 : 2
  exit(exit_code)
end

main(ARGV) if $PROGRAM_NAME == __FILE__
