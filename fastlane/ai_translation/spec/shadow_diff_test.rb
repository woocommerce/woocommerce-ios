# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../lib/woo_ai_translation/shadow_diff'

class ShadowDiffCategorizeTest < Minitest::Test
  def categorize(en, gp, ai)
    WooAiTranslation::ShadowDiff.categorize(en_source: en, gp_human: gp, ai_proposal: ai)
  end

  def test_identical_when_gp_and_ai_are_byte_identical
    assert_equal :identical, categorize('Hello', 'Hallo', 'Hallo')
  end

  def test_cosmetic_when_differ_only_by_whitespace
    assert_equal :cosmetic, categorize('Hello', 'Hallo  Welt', 'Hallo Welt')
  end

  def test_cosmetic_when_differ_only_by_case
    assert_equal :cosmetic, categorize('Hello', 'HALLO', 'hallo')
  end

  def test_placeholder_mismatch_when_ai_drops_placeholder
    # EN has %@; AI proposal omits it. Real bug.
    assert_equal :placeholder_mismatch,
                 categorize('Hello, %@!', 'Hallo, %@!', 'Hallo!')
  end

  def test_placeholder_mismatch_when_ai_changes_positional_index
    # AI changes %1$@ to %@ — different placeholder syntax, bug.
    assert_equal :placeholder_mismatch,
                 categorize('Welcome %1$@ to %2$@', 'Willkommen %1$@ in %2$@', 'Willkommen %@ in %@')
  end

  def test_placeholder_mismatch_when_gp_human_already_has_a_placeholder_bug
    # Even though AI matches EN, GP doesn't — still flag so reviewer sees the
    # pre-existing GP-side bug.
    assert_equal :placeholder_mismatch,
                 categorize('Hello %@', 'Hallo', 'Hallo %@')
  end

  def test_not_placeholder_mismatch_when_translation_reorders_placeholders
    # Both translations preserve the set %@,%@ even though word order differs.
    assert_equal :substantive,
                 categorize('Hello %@ from %@', 'Hallo %@ aus %@', 'Aus %@ Hallo %@')
  end

  def test_length_significant_when_ai_is_much_longer_than_gp
    # GP is short, AI is >20% longer in bytes.
    short_gp = 'Hi'
    long_ai = 'Greetings and welcome!'
    assert_equal :length_significant, categorize('Hi', short_gp, long_ai)
  end

  def test_length_significant_when_ai_is_much_shorter_than_gp
    long_gp = 'Greetings and welcome to the application!'
    short_ai = 'Hi'
    assert_equal :length_significant, categorize('Hi', long_gp, short_ai)
  end

  def test_substantive_when_real_word_change_within_length_bound
    # 20-byte phrase translated differently but similar length — substantive.
    assert_equal :substantive,
                 categorize('Cancel order', 'Bestellung stornieren', 'Auftrag abbrechen')
  end

  def test_extract_placeholders_returns_sorted_list_including_duplicates
    # Given a string with duplicate non-positional placeholders
    result = WooAiTranslation::ShadowDiff.extract_placeholders('%@ and %@ and %d')

    # Then duplicates are preserved (count matters) and sorting is stable
    assert_equal ['%@', '%@', '%d'], result
  end

  def test_extract_placeholders_handles_positional_indexed_forms
    result = WooAiTranslation::ShadowDiff.extract_placeholders('%1$@ said %2$@')
    assert_equal ['%1$@', '%2$@'], result
  end

  def test_extract_placeholders_returns_empty_for_text_without_placeholders
    assert_empty WooAiTranslation::ShadowDiff.extract_placeholders('plain text here')
  end

  def test_extract_placeholders_includes_literal_percent_token
    # Given a string with the literal-percent token `%%`. Dropping it desyncs
    # printf parsing, so it MUST be counted as a placeholder.
    result = WooAiTranslation::ShadowDiff.extract_placeholders('%.0f%% complete')

    # Then both the `%.0f` printf token AND the literal `%%` appear.
    assert_equal ['%%', '%.0f'], result
  end

  def test_placeholder_mismatch_when_ai_drops_literal_percent
    # Reproduces Codex round-3 finding: `%%` was not in the regex, so an AI
    # translation that dropped a literal-percent (corrupting printf parsing)
    # used to fall through to `substantive` instead of being flagged as a
    # hard-fail placeholder_mismatch.
    assert_equal :placeholder_mismatch,
                 categorize('%.0f%% complete', '%.0f%% abgeschlossen', '%.0f% abgeschlossen')
  end
end

class ShadowDiffSamplingTest < Minitest::Test
  def make_entry(key, bucket)
    WooAiTranslation::ShadowDiff::Entry.new(
      key: key, en_source: 'en', gp_human: 'gp', ai_proposal: 'ai',
      bucket: bucket, en_placeholders: [], gp_placeholders: [], ai_placeholders: []
    )
  end

  def test_samples_100_percent_of_placeholder_mismatch
    # Given 5 placeholder_mismatch entries (low count, should all appear)
    entries = (1..5).map { |i| make_entry("ph#{i}", :placeholder_mismatch) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    assert_equal 5, sampled.size
  end

  def test_samples_100_percent_of_length_significant
    entries = (1..7).map { |i| make_entry("ls#{i}", :length_significant) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    assert_equal 7, sampled.size
  end

  def test_samples_min_30_of_substantive_when_bucket_small
    # Given 20 substantive entries (smaller than the 30 floor)
    entries = (1..20).map { |i| make_entry("s#{i}", :substantive) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    # Then we take all 20 (can't exceed available)
    assert_equal 20, sampled.size
  end

  def test_samples_30_of_substantive_when_bucket_at_floor
    entries = (1..40).map { |i| make_entry("s#{i}", :substantive) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    # 40 * 5% = 2 < 30 floor → take 30
    assert_equal 30, sampled.size
  end

  def test_samples_5_percent_of_substantive_when_bucket_large
    entries = (1..2000).map { |i| make_entry("s#{i}", :substantive) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    # 2000 * 5% = 100 > 30 floor → take 100
    assert_equal 100, sampled.size
  end

  def test_excludes_cosmetic_from_worksheet
    entries = (1..50).map { |i| make_entry("c#{i}", :cosmetic) }
    sampled = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries)
    assert_empty sampled
  end

  def test_seed_makes_sampling_deterministic
    entries = (1..1000).map { |i| make_entry("s#{i}", :substantive) }
    first = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries, seed: 42).map(&:key)
    second = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries, seed: 42).map(&:key)
    assert_equal first, second
  end

  def test_different_seeds_produce_different_samples
    entries = (1..1000).map { |i| make_entry("s#{i}", :substantive) }
    first = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries, seed: 42).map(&:key)
    second = WooAiTranslation::ShadowDiff.sample_for_worksheet(entries, seed: 99).map(&:key)
    refute_equal first, second
  end

  def test_render_worksheet_passes_seed_through_to_sample_selection
    # Codex round-3 finding: the CLI calls sample_for_worksheet with the
    # user's seed to know which entries to feed the AI judge, but
    # render_worksheet used to call sample_for_worksheet AGAIN with the
    # default seed (42) — so the rendered rows and the judged entries
    # were different samples on any --seed != 42. This test pins that the
    # seed parameter threads through to the underlying sampling.
    entries = (1..1000).map { |i| make_entry("s#{i}", :substantive) }
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: 'de', diff_entries: entries)

    # When we render the worksheet with seed=99
    md = WooAiTranslation::ShadowDiff.render_worksheet(locale_result, seed: 99)

    # And we compute what the seed=99 sample would be directly
    sampled_keys = WooAiTranslation::ShadowDiff
                   .sample_for_worksheet(entries, seed: 99)
                   .map(&:key)

    # Then EVERY sampled key appears in the rendered worksheet — and the
    # rendered keys are NOT the default-seed (42) sample.
    sampled_keys.each { |k| assert_includes md, k }
    default_seed_keys = WooAiTranslation::ShadowDiff
                        .sample_for_worksheet(entries, seed: 42)
                        .map(&:key)
    # Reasonable confidence that seed=99 and seed=42 picked different
    # samples (overlap will exist for any random sample but should be
    # well under 100%).
    overlap = (sampled_keys & default_seed_keys).size
    assert overlap < sampled_keys.size, 'seed=99 and seed=42 samples should differ'
  end
end

class ShadowDiffSummaryTest < Minitest::Test
  def test_summary_counts_each_bucket
    entries = [
      WooAiTranslation::ShadowDiff::Entry.new(key: 'a', en_source: '', gp_human: '', ai_proposal: '',
                                              bucket: :identical, en_placeholders: [], gp_placeholders: [], ai_placeholders: []),
      WooAiTranslation::ShadowDiff::Entry.new(key: 'b', en_source: '', gp_human: '', ai_proposal: '',
                                              bucket: :identical, en_placeholders: [], gp_placeholders: [], ai_placeholders: []),
      WooAiTranslation::ShadowDiff::Entry.new(key: 'c', en_source: '', gp_human: '', ai_proposal: '',
                                              bucket: :substantive, en_placeholders: [], gp_placeholders: [], ai_placeholders: [])
    ]
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: 'de', diff_entries: entries)

    s = locale_result.summary

    assert_equal 3, s[:total]
    assert_equal 2, s[:identical]
    assert_equal 1, s[:substantive]
    assert_equal 0, s[:cosmetic]
  end
end

class ShadowDiffRenderingTest < Minitest::Test
  def test_render_summary_includes_all_bucket_rows
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(
      locale: 'de',
      diff_entries: [
        WooAiTranslation::ShadowDiff::Entry.new(key: 'k1', en_source: '', gp_human: '', ai_proposal: '',
                                                bucket: :identical, en_placeholders: [], gp_placeholders: [], ai_placeholders: [])
      ]
    )
    md = WooAiTranslation::ShadowDiff.render_summary(locale_result)

    assert_includes md, '## de'
    assert_includes md, 'identical'
    assert_includes md, 'cosmetic'
    assert_includes md, 'placeholder_mismatch'
    assert_includes md, 'length_significant'
    assert_includes md, 'substantive'
    assert_includes md, 'total'
  end

  def test_render_worksheet_includes_methodology_reminder_in_header
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: 'de', diff_entries: [])
    md = WooAiTranslation::ShadowDiff.render_worksheet(locale_result)
    # The "AI better / equivalent / GP better" rubric must be visible to the
    # reviewer so they read the right question.
    assert_includes md, 'comparative'
    assert_includes md, 'AI better'
    assert_includes md, 'GP better'
    assert_includes md, 'merchant audience'
  end

  def test_render_worksheet_includes_advisory_column_when_judge_provided
    entries = [
      WooAiTranslation::ShadowDiff::Entry.new(key: 'k1', en_source: 'Hello', gp_human: 'Hallo Welt',
                                              ai_proposal: 'Hi Welt', bucket: :length_significant,
                                              en_placeholders: [], gp_placeholders: [], ai_placeholders: [])
    ]
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: 'de', diff_entries: entries)
    advisory = { 'k1' => 'equivalent' }

    md = WooAiTranslation::ShadowDiff.render_worksheet(locale_result, ai_judge_advisory: advisory)

    assert_includes md, 'Judge (advisory)'
    assert_includes md, 'equivalent'
  end

  def test_render_worksheet_escapes_pipe_in_content
    entries = [
      WooAiTranslation::ShadowDiff::Entry.new(key: 'pipe', en_source: 'a|b', gp_human: 'c|d', ai_proposal: 'e|f',
                                              bucket: :length_significant, en_placeholders: [], gp_placeholders: [], ai_placeholders: [])
    ]
    locale_result = WooAiTranslation::ShadowDiff::LocaleResult.new(locale: 'de', diff_entries: entries)

    md = WooAiTranslation::ShadowDiff.render_worksheet(locale_result)
    # Pipe should be escaped so the Markdown table doesn't break
    assert_includes md, 'a\\|b'
    assert_includes md, 'c\\|d'
    assert_includes md, 'e\\|f'
  end
end
