# frozen_string_literal: true

{
  repository: 'woocommerce/woocommerce-ios',
  versioning: { platform: :ios, scheme: :marketing, file: 'config/Version.Public.xcconfig' },
  hotfix: { version_option: :version, base_policy: :tag_or_release_branch },
  milestones: { annotation_context: 'start-code-freeze' },
  build: {
    pipeline: 'woocommerce-ios', pipeline_file: 'release-builds.yml', beta_environment: 'IS_BETA_RELEASE'
  }
}
