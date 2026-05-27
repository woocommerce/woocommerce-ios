# frozen_string_literal: true

module WooAiTranslation
  # Mapping of iOS locale codes (matching `<locale>.lproj` folder names under
  # `WooCommerce/Resources/`) to App Store Connect locale codes for the 14
  # AI-translated locales.
  #
  # Two intentional asymmetries vs the 15-locale in-app list in
  # `fastlane/ai_translation/Rakefile`:
  #
  #   - `bg` is excluded: Apple does not offer a Bulgarian App Store
  #     listing. Bulgarian iOS users see the fully-translated app but the
  #     English ASC listing. This matches the decision shipped with PR 5
  #     ([#17271](https://github.com/woocommerce/woocommerce-ios/pull/17271)).
  #
  #   - `nb` (Norwegian Bokmål) maps to ASC `no`. Apple's App Store has only a
  #     generic Norwegian listing, not a Bokmål-specific one. Acceptable lossy
  #     mapping — Bokmål is the dominant written form.
  #
  # The remaining 16 ASC locales (ar-SA, de-DE, es-ES, fr-FR, he, id, it, ja,
  # ko, nl-NL, pt-BR, ru, sv, tr, zh-Hans, zh-Hant) still receive their
  # human-curated metadata from GlotPress; this list is the AI-only delta.
  module AscLocales
    # iOS locale code => ASC locale code.
    AI_TRANSLATION_LOCALES = {
      'cs' => 'cs',
      'da' => 'da',
      'el' => 'el',
      'fi' => 'fi',
      'hi' => 'hi',
      'hu' => 'hu',
      'ms' => 'ms',
      'nb' => 'no',
      'pl' => 'pl',
      'pt-PT' => 'pt-PT',
      'ro' => 'ro',
      'th' => 'th',
      'uk' => 'uk',
      'vi' => 'vi'
    }.freeze
  end
end
