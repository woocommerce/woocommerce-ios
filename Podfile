# frozen_string_literal: true

require 'cocoapods-catalyst-support'

# For security reasons, please always keep the wordpress-mobile source first and the CDN second.
# For more info, see https://github.com/wordpress-mobile/cocoapods-specs#source-order-and-security-considerations
install! 'cocoapods', warn_for_multiple_pod_sources: false
source 'https://github.com/wordpress-mobile/cocoapods-specs.git'
source 'https://cdn.cocoapods.org/'

raise 'Please run CocoaPods via `bundle exec`' unless %w[BUNDLE_BIN_PATH BUNDLE_GEMFILE].any? { |k| ENV.key?(k) }

inhibit_all_warnings!
use_frameworks! # Defaulting to use_frameworks! See pre_install hook below for static linking.
use_modular_headers!

app_ios_deployment_target = Gem::Version.new('16.0')

platform :ios, app_ios_deployment_target.version
workspace 'WooCommerce.xcworkspace'

# Main Target!
# ============
#
target 'WooCommerce' do
  project 'WooCommerce/WooCommerce.xcodeproj'

  # Automattic Libraries
  # ====================
  #

  # Unit Tests
  # ==========
  #
  target 'WooCommerceTests' do
    inherit! :search_paths
  end
end

# Yosemite Layer:
# ===============
#
# Yosemite Target:
# ================
#
target 'Yosemite' do
  project 'Yosemite/Yosemite.xcodeproj'
  # Empty, but if we remove this we get a CocoaPods crash.
  #
  # ArgumentError - [Xcodeproj] Unable to find compatibility version string for object version `70`.
  #
  # Given we're in the process of removing CocoaPods, we can ignore this for
  # the time being.
end

# Workarounds:
# ============
#

# Static Frameworks:
# ============
#
# Make all pods that are not shared across multiple targets into static frameworks by overriding the static_framework? function to return true
# Linking the shared frameworks statically would lead to duplicate symbols
# A future version of CocoaPods may make this easier to do. See https://github.com/CocoaPods/CocoaPods/issues/7428
shared_targets = %w[Storage Hardware]
# Statically linking Sentry results in a conflict with `NSDictionary.objectAtKeyPath`, but dynamically
# linking it resolves this.
dynamic_pods = ['Sentry']
pre_install do |installer|
  static = []
  dynamic = []
  installer.pod_targets.each do |pod|
    # If this pod is a dependency of one of our shared targets or its explicitly excluded, it must be linked dynamically
    if pod.target_definitions.any? { |t| shared_targets.include? t.name } || dynamic_pods.include?(pod.name)
      dynamic << pod
      next
    end
    static << pod
    def pod.static_framework?
      true
    end
  end

  puts "Installing #{static.count} pods as static frameworks"
  puts "Installing #{dynamic.count} pods as dynamic frameworks"

  # Force CocoaLumberjack Swift version
  installer.analysis_result.specifications.each do |s|
    s.swift_version = '5.0' if s.name == 'CocoaLumberjack'
  end
end

# Configure your macCatalyst dependencies
catalyst_configuration do
  # Uncomment the next line for a verbose output
  # verbose!

  # ios '<pod_name>' # This dependency will only be available for iOS
  ios 'StripeTerminal'
  ios 'ZendeskSupportSDK'
  # macos '<pod_name>' # This dependency will only be available for macOS
end

post_install do |installer|
  installer.configure_catalyst
  # Workaround: Drop 32 Bit Architectures
  # =====================================
  #
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['VALID_ARCHS'] = '$(ARCHS_STANDARD)'
  end

  # Let Pods targets inherit deployment target from the app
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/4859
  # =====================================
  #
  installer.pods_project.targets.each do |target|
    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    if target.respond_to?(:product_type) && (target.product_type == 'com.apple.product-type.bundle')
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
      end
    end
    target.build_configurations.each do |configuration|
      pod_ios_deployment_target = Gem::Version.new(configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
      configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET' if pod_ios_deployment_target <= app_ios_deployment_target
    end
  end

  # Flag Alpha builds for Tracks
  # ============================
  # rubocop:disable Style/CombinableLoops
  installer.pods_project.targets.each do |target|
    next unless target.name == 'Automattic-Tracks-iOS'

    target.build_configurations.each do |config|
      next unless config.name == 'Release-Alpha'

      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'ALPHA=1']
    end
  end

  # Fix a code signing issue in Xcode 14 beta.
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/11402#issuecomment-1189861270
  # ====================================
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
    end
  end
  # rubocop:enable Style/CombinableLoops
end
