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

  # --- Word-boundary brand matching (regression for substring false positives) ---

  def test_brand_safety_ignores_brand_as_substring_of_a_larger_word
    # "Woo" is a brand, but here it only appears inside "Wood" — not a standalone
    # token. Bare-substring matching used to flag this and demand "Woo" in the
    # translation; word-boundary matching must let it pass.
    out = @v.validate(source: 'Wood paneling', translation: 'Panele drewniane')
    assert_empty out
  end

  def test_brand_safety_still_flags_standalone_brand_with_adjacent_punctuation
    # Punctuation is a boundary, so "(WooCommerce)" is still a standalone token.
    out = @v.validate(source: 'Open (WooCommerce)', translation: 'Otwórz (sklep)')
    assert_equal 1, out.size
    assert_equal 'WooCommerce', out.first[:term]
  end

  def test_brand_safety_passes_when_standalone_brand_preserved_with_punctuation
    out = @v.validate(source: 'Open (WooCommerce)', translation: 'Otwórz (WooCommerce)')
    assert_empty out
  end

  # --- Real shipped glossary: generic tokens were pruned (Finding A) ----------

  REAL_GLOSSARY_DIR = File.expand_path('../glossary', __dir__)

  # 'zz' has no per-locale glossary file, so the validator applies only the
  # real common.yml brand rules — isolating these tests to brand-safety.
  def real_common_validator(locale: 'zz')
    WooAiTranslation::Validator.for_locale(locale: locale, base_dir: REAL_GLOSSARY_DIR)
  end

  def test_real_common_glossary_excludes_generic_substring_tokens
    brands = real_common_validator.brands
    %w[X Mail POS PIN].each do |token|
      refute_includes brands, token, "#{token.inspect} must stay out of common.yml: it collides with ordinary copy"
    end
  end

  def test_real_common_glossary_keeps_unambiguous_brands
    brands = real_common_validator.brands
    assert_includes brands, 'WooCommerce'
    assert_includes brands, 'Point of Sale'
  end

  def test_real_common_glossary_does_not_flag_words_containing_dropped_tokens
    v = real_common_validator
    # Each source embeds a pruned token as a substring (PIN⊂SHIPPING, POS⊂Position,
    # Mail⊂Email) or as a bare letter (X). None should raise a brand violation.
    assert_empty v.validate(source: 'SHIPPING ADDRESS', translation: 'ENDEREÇO DE ENVIO')
    assert_empty v.validate(source: 'Position', translation: 'Posição')
    assert_empty v.validate(source: 'Email address', translation: 'Endereço de email')
    assert_empty v.validate(source: 'Size: 5 x 3', translation: 'Tamanho: 5 x 3')
  end
end
