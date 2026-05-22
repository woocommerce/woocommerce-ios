# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/woo_ai_translation/byte_sizer'

class ByteSizerTest < Minitest::Test
  def test_latin_locale_gets_largest_batch
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    assert_operator sizer.recommended_batch_size(locale: 'pl'), :>, 60
    assert_operator sizer.recommended_batch_size(locale: 'fi'), :>, 60
  end

  def test_devanagari_smaller_than_latin
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    pl = sizer.recommended_batch_size(locale: 'pl')
    hi = sizer.recommended_batch_size(locale: 'hi')
    assert_operator hi, :<, pl, 'Devanagari should yield a smaller batch than Latin'
  end

  def test_thai_smaller_than_latin
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    pl = sizer.recommended_batch_size(locale: 'pl')
    th = sizer.recommended_batch_size(locale: 'th')
    assert_operator th, :<, pl, 'Thai should yield a smaller batch than Latin'
  end

  def test_cyrillic_between_latin_and_devanagari
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    pl = sizer.recommended_batch_size(locale: 'pl')
    bg = sizer.recommended_batch_size(locale: 'bg')
    hi = sizer.recommended_batch_size(locale: 'hi')
    assert_operator bg, :<=, pl
    assert_operator bg, :>=, hi
  end

  def test_unknown_locale_defaults_to_latin
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    assert_equal :latin, sizer.script_for(locale: 'xx')
    pl = sizer.recommended_batch_size(locale: 'pl')
    xx = sizer.recommended_batch_size(locale: 'xx')
    assert_equal pl, xx
  end

  def test_larger_output_budget_yields_larger_batch
    small = WooAiTranslation::ByteSizer.new(max_output_tokens: 8192)
    large = WooAiTranslation::ByteSizer.new(max_output_tokens: 32_768)
    assert_operator large.recommended_batch_size(locale: 'pl'), :>,
                    small.recommended_batch_size(locale: 'pl')
  end

  def test_batch_size_never_zero_for_extreme_settings
    sizer = WooAiTranslation::ByteSizer.new(max_output_tokens: 50,
                                            source_bytes_per_entry: 5000)
    assert_operator sizer.recommended_batch_size(locale: 'hi'), :>=, 1
  end

  def test_tokens_per_entry_monotone_with_script_density
    sizer = WooAiTranslation::ByteSizer.new
    latin = sizer.tokens_per_entry(locale: 'pl')
    cyrillic = sizer.tokens_per_entry(locale: 'bg')
    devanagari = sizer.tokens_per_entry(locale: 'hi')
    assert_operator latin, :<=, cyrillic
    assert_operator cyrillic, :<=, devanagari
  end

  def test_script_for_known_locales
    sizer = WooAiTranslation::ByteSizer.new
    assert_equal :cyrillic, sizer.script_for(locale: 'bg')
    assert_equal :devanagari, sizer.script_for(locale: 'hi')
    assert_equal :thai, sizer.script_for(locale: 'th')
    assert_equal :cjk, sizer.script_for(locale: 'ja')
    assert_equal :greek, sizer.script_for(locale: 'el')
    assert_equal :latin, sizer.script_for(locale: 'fi')
  end
end
