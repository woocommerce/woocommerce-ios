#!/usr/bin/env ruby
# frozen_string_literal: true

# Shadow-diff calibration tool. Translates an existing GlotPress-translated
# locale via the production AI engine and diffs the result against the
# human-curated GP translation. Outputs:
#
#   - A per-locale Markdown worksheet for native-speaker reviewers (Tier 3)
#   - A per-locale Markdown summary report (counts per bucket)
#   - A combined index report
#
# Use this to gather comparative-quality data ahead of any GlotPress sunset
# conversation (PR 8). The tool does NOT decide quality; humans do. See the
# fastlane/ai_translation/README.md "Shadow-diff calibration" section.
#
# Usage:
#   bin/translate_shadow_diff.rb \
#     --locales de,es,fr,ja \
#     --output ./shadow-diff-out
#
# Flags:
#   --locales LIST           Comma-separated GP locale codes to evaluate (required).
#   --output DIR             Output directory for worksheets + reports (default: ./shadow-diff-out).
#   --limit N                Cap keys per locale (smoke runs; default: all).
#   --judge-model NAME       Tier 2 judge model (e.g. "gpt-5.1"). Omit to skip Tier 2.
#   --seed N                 Sampling seed for reproducibility (default: 42).
#   --offline                Use deterministic StubClient for translation (no API spend).

require 'optparse'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'))

require 'woo_ai_translation/ai_judge'
require 'woo_ai_translation/anthropic_client'
require 'woo_ai_translation/constants'
require 'woo_ai_translation/ios_resources'
require 'woo_ai_translation/openai_client'
require 'woo_ai_translation/shadow_diff'
require 'woo_ai_translation/translator'
require 'woo_ai_translation/validator'

REPO_ROOT = File.expand_path('../..', ROOT)
RESOURCES = File.join(REPO_ROOT, 'WooCommerce/Resources')

options = {
  locales: nil,
  output: File.join(Dir.pwd, 'shadow-diff-out'),
  limit: nil,
  judge_model: nil,
  seed: 42,
  offline: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: translate_shadow_diff.rb --locales de,es,fr,ja [--output DIR] [--limit N] [--judge-model NAME] [--seed N] [--offline]'
  opts.on('--locales LIST', 'Comma-separated GP locale codes (required)') { |v| options[:locales] = v.split(',').map(&:strip) }
  opts.on('--output DIR', 'Output directory for worksheets + reports') { |v| options[:output] = v }
  opts.on('--limit N', Integer, 'Cap keys per locale') { |v| options[:limit] = v }
  opts.on('--judge-model NAME', 'Tier 2 judge model (omit to skip Tier 2)') { |v| options[:judge_model] = v }
  opts.on('--seed N', Integer, 'Sampling seed (default 42)') { |v| options[:seed] = v }
  opts.on('--offline', 'Use deterministic StubClient (no API calls)') { options[:offline] = true }
end.parse!

abort 'error: --locales is required (comma-separated GP locale codes)' if options[:locales].nil? || options[:locales].empty?

# --- Set up clients ---

anthropic =
  if options[:offline]
    WooAiTranslation::StubClient.new
  else
    c = WooAiTranslation::AnthropicClient.from_env
    abort 'error: ANTHROPIC_API_KEY is not set (use --offline for a dry run)' unless c.available?
    c
  end

ai_judge = nil
if options[:judge_model] && !options[:offline]
  oai = WooAiTranslation::OpenAIClient.from_env
  abort "error: OPENAI_API_KEY is not set (required for --judge-model #{options[:judge_model]})" unless oai.available?

  ai_judge = WooAiTranslation::AiJudge.new(client: oai, model: options[:judge_model])
elsif options[:judge_model] && options[:offline]
  warn 'warn: --judge-model ignored in --offline mode'
end

translator = WooAiTranslation::Translator.new(
  client: anthropic,
  logger: ->(msg) { warn "[translator] #{msg}" }
)

style_dir = File.join(ROOT, 'style')

FileUtils.mkdir_p(options[:output])

# --- Run per locale ---

en_path = File.join(RESOURCES, 'en.lproj/Localizable.strings')
abort "error: EN source not found at #{en_path}" unless File.exist?(en_path)

warn "Reading EN source: #{en_path}"
en_doc = WooAiTranslation::IosResources::Parser.parse_file(en_path)
en_by_name = en_doc.units.to_h { |u| [u.name, u.entries.first[:source]] }

summaries = []

options[:locales].each do |locale|
  gp_path = File.join(RESOURCES, "#{locale}.lproj/Localizable.strings")
  unless File.exist?(gp_path)
    warn "warn: skipping #{locale} — GP file not found at #{gp_path}"
    next
  end

  warn "Reading GP locale #{locale}: #{gp_path}"
  gp_doc = WooAiTranslation::IosResources::Parser.parse_file(gp_path)
  gp_by_name = gp_doc.units.to_h { |u| [u.name, u.entries.first[:source]] }

  # Intersect keys: only shadow-diff keys that exist in BOTH EN and GP.
  shared_keys = en_by_name.keys & gp_by_name.keys
  shared_keys = shared_keys.first(options[:limit]) if options[:limit]
  warn "Locale #{locale}: #{shared_keys.size} keys to shadow-diff"

  # AI-translate the shared keys.
  items = shared_keys.map { |k| { id: k, source: en_by_name[k], context: en_doc.units.find { |u| u.name == k }&.comment.to_s } }
  warn "Locale #{locale}: requesting AI translations (model=#{WooAiTranslation::DEFAULT_MODEL}, offline=#{options[:offline]})..."

  ai_proposals = translator.translate(
    locale: locale,
    items: items,
    model: WooAiTranslation::DEFAULT_MODEL,
    style: File.exist?(File.join(style_dir, "#{locale}.md")) ? File.read(File.join(style_dir, "#{locale}.md")) : nil
  )

  warn "Locale #{locale}: categorizing #{shared_keys.size} entries..."

  entries = shared_keys.map do |key|
    en_source = en_by_name[key]
    gp_human = gp_by_name[key]
    ai_proposal = ai_proposals[key] || ''

    WooAiTranslation::ShadowDiff.build_entry(
      key: key,
      en_source: en_source,
      gp_human: gp_human,
      ai_proposal: ai_proposal
    )
  end

  locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: locale, diff_entries: entries)

  # Tier 2 AI judge — only on the worksheet sample.
  advisory = nil
  if ai_judge
    sample = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries, seed: options[:seed])
    warn "Locale #{locale}: running Tier 2 AI judge over #{sample.size} sampled entries..."
    advisory = ai_judge.judge_all(sample)
  end

  # Write worksheet + summary.
  worksheet_path = File.join(options[:output], "#{locale}-worksheet.md")
  summary_path = File.join(options[:output], "#{locale}-summary.md")
  File.write(worksheet_path, WooAiTranslation::ShadowDiff.render_worksheet(locale_result, ai_judge_advisory: advisory))
  File.write(summary_path, WooAiTranslation::ShadowDiff.render_summary(locale_result))

  summaries << locale_result.summary.merge(locale: locale)
  warn "Locale #{locale}: wrote #{worksheet_path} + #{summary_path}"
end

# --- Combined index report ---

index_lines = ['# Shadow-diff calibration — combined summary', '']
index_lines << '_Reviewer worksheet for Tier 3 (human native-speaker judgment) lives alongside each summary._'
index_lines << ''
index_lines << '| Locale | Total | Identical | Cosmetic | Placeholder ⚠ | Length-significant | Substantive |'
index_lines << '|---|---:|---:|---:|---:|---:|---:|'
summaries.each do |s|
  index_lines << "| #{s[:locale]} | #{s[:total]} | #{s[:identical]} | #{s[:cosmetic]} | #{s[:placeholder_mismatch]} | #{s[:length_significant]} | #{s[:substantive]} |"
end
File.write(File.join(options[:output], 'index.md'), index_lines.join("\n"))
warn "Wrote #{File.join(options[:output], 'index.md')}"

# --- Stdout summary table ---

def summary_row(cells)
  widths = [8, 7, 9, 8, 13, 18, 12]
  cells.each_with_index.map { |c, i| widths[i] ? c.to_s.ljust(widths[i]) : c.to_s }.join('  ')
end

puts ''
puts '=== Shadow-diff summary ==='
puts summary_row(%w[Locale Total Identical Cosmetic Placeholder Length-significant Substantive])
summaries.each do |s|
  puts summary_row([s[:locale], s[:total], s[:identical], s[:cosmetic], s[:placeholder_mismatch], s[:length_significant], s[:substantive]])
end
puts ''
puts "Output written to: #{options[:output]}/"
puts 'Reviewers (Tier 3): see <locale>-worksheet.md per locale.'

exit 0
