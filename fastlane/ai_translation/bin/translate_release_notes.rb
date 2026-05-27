#!/usr/bin/env ruby
# frozen_string_literal: true

# Translate the English App Store `release_notes.txt` into the 14 AI locales
# and write the result to each `fastlane/metadata/<asc_locale>/release_notes.txt`.
# Invoked from the `translate_release_notes_ai_locales` Fastlane lane during the
# release-translations Buildkite step.
#
# Per-locale failures (empty, validator violation, length overflow) are soft:
# the locale is skipped and Apple's automatic English fallback handles it.
# The script exits non-zero only on infrastructure errors (missing source,
# missing API key on a non-offline run).
#
# Usage:
#   bin/translate_release_notes.rb \
#     --source fastlane/metadata/default/release_notes.txt \
#     --metadata-dir fastlane/metadata
#
# Flags:
#   --offline            Use the deterministic StubClient (no network, no spend).
#   --model NAME         Override the default Haiku model used on the first attempt.

require 'optparse'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'))

require 'woo_ai_translation/anthropic_client'
require 'woo_ai_translation/asc_locales'
require 'woo_ai_translation/constants'
require 'woo_ai_translation/release_notes_translator'

options = { offline: false, model: nil }
OptionParser.new do |opts|
  opts.banner = 'Usage: translate_release_notes.rb --source PATH --metadata-dir PATH [--offline] [--model NAME]'
  opts.on('--source PATH', 'EN release_notes.txt path (required)') { |v| options[:source] = v }
  opts.on('--metadata-dir PATH', 'fastlane/metadata root (required)') { |v| options[:metadata_dir] = v }
  opts.on('--offline', 'Use deterministic StubClient (no API calls)') { options[:offline] = true }
  opts.on('--model NAME', 'Override first-attempt model') { |v| options[:model] = v }
end.parse!

abort 'error: --source is required' unless options[:source]
abort 'error: --metadata-dir is required' unless options[:metadata_dir]

source_path = options[:source]
abort "error: source file not found: #{source_path}" unless File.exist?(source_path)

source_text = File.read(source_path).strip
abort "error: source file is empty: #{source_path}" if source_text.empty?

client =
  if options[:offline]
    WooAiTranslation::StubClient.new
  else
    c = WooAiTranslation::AnthropicClient.from_env
    abort 'error: ANTHROPIC_API_KEY is not set (use --offline for a dry run)' unless c.available?
    c
  end

glossary_dir = File.join(ROOT, 'glossary')
style_dir = File.join(ROOT, 'style')

orchestrator = WooAiTranslation::ReleaseNotesTranslator.new(
  client: client,
  glossary_dir: glossary_dir,
  style_dir: style_dir,
  logger: ->(msg) { warn msg }
)

# Allow CLI override of the first-attempt model. We can't easily thread it
# through the orchestrator without bloating its API, so we monkey-patch the
# constant for this process only. Acceptable since this is a single-purpose CLI.
if options[:model]
  WooAiTranslation.send(:remove_const, :DEFAULT_MODEL)
  WooAiTranslation.const_set(:DEFAULT_MODEL, options[:model])
end

results = []
WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES.each do |ios_locale, asc_locale|
  result = orchestrator.translate(
    source_text: source_text,
    locale: ios_locale,
    asc_locale: asc_locale
  )
  results << result

  next unless result.status == :translated

  target_dir = File.join(options[:metadata_dir], asc_locale)
  FileUtils.mkdir_p(target_dir)
  File.write(File.join(target_dir, 'release_notes.txt'), "#{result.translation.strip}\n")
end

# Plain-text summary. Buildkite log + Fastlane annotation both render fine.
def row(cells)
  widths = [7, 7, 10, 15]
  padded = cells.each_with_index.map { |c, i| widths[i] ? c.to_s.ljust(widths[i]) : c.to_s }
  padded.join('  ')
end

puts ''
puts '=== AI release-notes translation summary ==='
puts row(%w[iOS ASC Status Model Notes])
puts row(%w[--- --- ------ ----- -----])
results.each do |r|
  status = r.status == :translated ? '✓ done' : '✗ skipped'
  notes = r.status == :translated ? '' : r.skip_reason.to_s
  puts row([r.locale, r.asc_locale, status, r.model, notes])
end

skipped = results.count { |r| r.status == :skipped }
translated = results.size - skipped
puts ''
puts "Translated: #{translated}/#{results.size}  Skipped: #{skipped} (English fallback)"

# Always exit zero: per-locale failures are not infrastructure failures.
exit 0
