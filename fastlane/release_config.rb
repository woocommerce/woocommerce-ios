# frozen_string_literal: true

{
  repository: 'woocommerce/woocommerce-ios',
  versioning: { platform: :ios, scheme: :marketing, file: 'config/Version.Public.xcconfig' },
  hotfix: { version_option: :version, base_policy: :tag_or_release_branch },
  code_freeze: { branch_protection: :copy_default },
  milestones: { annotation_context: 'start-code-freeze' },
  build: {
    pipeline: 'woocommerce-ios', pipeline_file: 'release-builds.yml', beta_environment: 'IS_BETA_RELEASE'
  },
  preparation: { freeze_after_version: :prepare_freeze_notes, beta: :prepare_beta_localizations, freeze_completion: :prepare_code_freeze }
}
