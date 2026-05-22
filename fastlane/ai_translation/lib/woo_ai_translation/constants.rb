# frozen_string_literal: true

module WooAiTranslation
  VERSION = '0.1.0-ios-pilot'

  # Bumping PROMPT_VERSION re-translates everything. Pinned for the pilot.
  PROMPT_VERSION = '2026-05-20.ios-pilot.1'

  # Anthropic API version header.
  ANTHROPIC_VERSION = '2023-06-01'

  # Default model. Haiku 4.5 was preferred over human translations 2-3x in the
  # Peacock P2 hack-week blind A/B (cf. android_resources project Phase 6).
  # CI should override with a date-pinned variant for full determinism.
  DEFAULT_MODEL = 'claude-haiku-4-5'
  ESCALATION_MODEL = 'claude-opus-4-7'
end
