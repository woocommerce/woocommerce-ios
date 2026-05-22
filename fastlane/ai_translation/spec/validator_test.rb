# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/woo_ai_translation/validator'

class ValidatorTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, 'common.yml'), <<~YAML)
      brands:
        - WooCommerce
        - Woo
      payments:
        - Stripe
        - Apple Pay
    YAML
    File.write(File.join(@dir, 'pl.yml'), <<~YAML)
      ui_terms:
        Cancel: Anuluj
        Save: Zapisz
      nouns:
        Orders: Zamówienia
    YAML
    @v = WooAiTranslation::Validator.for_locale(locale: 'pl', base_dir: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def test_brand_safety_passes_when_brand_preserved
    out = @v.validate(source: 'Connect WooCommerce', translation: 'Połącz WooCommerce')
    assert_empty out
  end

  def test_brand_safety_fails_when_brand_translated_or_dropped
    out = @v.validate(source: 'Connect WooCommerce', translation: 'Połącz sklep')
    assert_equal 1, out.size
    assert_equal :brand_safety, out.first[:rule]
    assert_equal 'WooCommerce', out.first[:term]
  end

  def test_brand_safety_catches_multi_word_brand
    out = @v.validate(source: 'Configure Apple Pay', translation: 'Skonfiguruj Płatność Apple')
    assert_equal 1, out.size
    assert_equal 'Apple Pay', out.first[:term]
  end

  def test_glossary_enforces_canonical_term_when_source_equals_key
    out = @v.validate(source: 'Cancel', translation: 'Wstecz')
    assert_equal 1, out.size
    assert_equal :glossary, out.first[:rule]
    assert_equal 'Cancel', out.first[:term]
    assert_equal 'Anuluj', out.first[:expected]
  end

  def test_glossary_accepts_canonical_translation
    out = @v.validate(source: 'Cancel', translation: 'Anuluj')
    assert_empty out
  end

  def test_glossary_case_insensitive_key_match
    out = @v.validate(source: 'cancel', translation: 'Anuluj')
    assert_empty out
  end

  def test_glossary_only_enforces_on_exact_source_match
    # "Cancel order" contains "Cancel" but is not the glossary key — no enforcement
    out = @v.validate(source: 'Cancel order', translation: 'Anuluj zamówienie')
    assert_empty out
  end

  def test_glossary_picks_up_nouns_section
    out = @v.validate(source: 'Orders', translation: 'Zamowienia') # missing diacritic
    assert_equal 1, out.size
    assert_equal 'Orders', out.first[:term]
    assert_equal 'Zamówienia', out.first[:expected]
  end

  def test_multiple_brand_violations_reported
    out = @v.validate(source: 'WooCommerce + Stripe + Apple Pay', translation: 'Sklep + Pasek + Płatność')
    assert_equal 3, out.size
    rules = out.map { |v| v[:rule] }.uniq
    assert_equal [:brand_safety], rules
  end

  def test_missing_glossary_file_falls_back_to_brands_only
    v = WooAiTranslation::Validator.for_locale(locale: 'xx', base_dir: @dir)
    assert_empty v.validate(source: 'Cancel', translation: 'whatever')
    out = v.validate(source: 'WooCommerce', translation: 'sklep')
    assert_equal 1, out.size
    assert_equal :brand_safety, out.first[:rule]
  end

  def test_brands_list_collected_across_yaml_sections
    assert_includes @v.brands, 'WooCommerce'
    assert_includes @v.brands, 'Stripe'
    assert_includes @v.brands, 'Apple Pay'
  end

  def test_terms_collected_from_ui_terms_and_nouns
    assert_equal 'Anuluj', @v.terms['Cancel']
    assert_equal 'Zamówienia', @v.terms['Orders']
  end
end
