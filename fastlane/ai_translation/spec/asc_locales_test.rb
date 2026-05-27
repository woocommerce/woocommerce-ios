# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/woo_ai_translation/asc_locales'

class AscLocalesTest < Minitest::Test
  def test_includes_all_14_expected_codes
    # Given the 15 iOS-cutover locales minus bg (unsupported by ASC)
    expected_ios = %w[cs da el fi hi hu ms nb pl pt-PT ro th uk vi].sort
    actual_ios = WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES.keys.sort
    assert_equal expected_ios, actual_ios
  end

  def test_ios_nb_maps_to_asc_no
    # Apple's App Store has no Bokmål-specific listing — map to generic `no`.
    assert_equal 'no', WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES['nb']
  end

  def test_bg_is_intentionally_absent
    # Bulgarian is excluded: Apple ASC does not support it. Bulgarian users
    # see the English ASC listing while the in-app strings remain translated.
    refute WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES.key?('bg')
  end

  def test_most_codes_map_to_themselves
    # Sanity check — only nb has a lossy mapping. Every other code is a 1:1.
    one_to_one = WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES.reject { |ios, asc| ios == asc }
    assert_equal({ 'nb' => 'no' }, one_to_one)
  end

  def test_mapping_is_frozen
    assert WooAiTranslation::AscLocales::AI_TRANSLATION_LOCALES.frozen?
  end
end
