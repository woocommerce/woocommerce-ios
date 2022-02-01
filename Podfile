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

app_ios_deployment_target = Gem::Version.new('14.0')

platform :ios, app_ios_deployment_target.version
workspace 'WooCommerce.xcworkspace'

## Pods shared between all the targets
## ===================================
##
def aztec
  pod 'WordPress-Editor-iOS', '~> 1.11.0'
end

# Main Target!
# ============
#
target 'WooCommerce' do
  project 'WooCommerce/WooCommerce.xcodeproj'

  # Automattic Libraries
  # ====================
  #

  #pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :branch => 'add/build-configuration'
  pod 'Automattic-Tracks-iOS', '~> 0.9.1'

  pod 'Gridicons', '~> 1.0'

  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  pod 'WordPressAuthenticator', '~> 1.42.0'
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => ''
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => ''
  # pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'

  pod 'WordPressShared', '~> 1.15'

  pod 'WordPressUI', '~> 1.12.1'
  # pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :branch => ''

  aztec

  pod 'WPMediaPicker', '~> 1.8.1'

  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.8'
  pod 'KeychainAccess', '~> 3.2'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
  pod 'XLPagerTabStrip', '~> 9.0'
  pod 'Charts', '~> 3.6.0'
  pod 'ZendeskSupportSDK', '~> 5.0'
  pod 'StripeTerminal', '~> 2.4'
  pod 'Kingfisher', '~> 6.0.0'
  pod 'Wormholy', '~> 1.6.5', configurations: ['Debug']

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
def yosemite_pods
  pod 'Alamofire', '~> 4.8'
  pod 'StripeTerminal', '~> 2.4'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'

  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  pod 'WordPressKit', '~> 4.40.0'
  # pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :branch => ''

  aztec
end

# Yosemite Target:
# ================
#
target 'Yosemite' do
  project 'Yosemite/Yosemite.xcodeproj'
  yosemite_pods
end

# Unit Tests
# ==========
#
target 'YosemiteTests' do
  project 'Yosemite/Yosemite.xcodeproj'
  yosemite_pods
end

# Networking Layer:
# =================
#
def networking_pods
  pod 'Alamofire', '~> 4.8'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'

  pod 'Sourcery', '~> 1.0.3', configuration: 'Debug'

  # Used for HTML parsing
  aztec
end

# Networking Target:
# ==================
#
target 'Networking' do
  project 'Networking/Networking.xcodeproj'
  networking_pods
end

# Unit Tests
# ==========
#
target 'NetworkingTests' do
  project 'Networking/Networking.xcodeproj'
  networking_pods

  # Including `yosemite_pods` because `Fakes.framework` has a dependency `Yosemite` while `Networking` does not.
  yosemite_pods
end

# Storage Layer:
# ==============
#
def storage_pods
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
end

# Storage Target:
# ===============
#
target 'Storage' do
  project 'Storage/Storage.xcodeproj'
  storage_pods
end

# Unit Tests
# ==========
#
target 'StorageTests' do
  project 'Storage/Storage.xcodeproj'
  storage_pods
end

# Hardware Layer:
# =================
#
def hardware_pods
  pod 'StripeTerminal', '~> 2.4'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
end

# Hardware Target:
# ==================
#
target 'Hardware' do
  project 'Hardware/Hardware.xcodeproj'
  hardware_pods
end

# Unit Tests
# ==========
#
target 'HardwareTests' do
  project 'Hardware/Hardware.xcodeproj'
  hardware_pods
end

# SampleReceiptPrinter Target:
# ==================
#
target 'SampleReceiptPrinter' do
  project 'Hardware/Hardware.xcodeproj'
  hardware_pods
end

# Experiments Layer:
# ==================
#
def experiments_pods
  pod 'Automattic-Tracks-iOS', '~> 0.9.1'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
end

# Experiments Target:
# ===================
#
target 'Experiments' do
  project 'Experiments/Experiments.xcodeproj'
  experiments_pods
end

# Unit Tests
# ==========
#
target 'ExperimentsTests' do
  project 'Experiments/Experiments.xcodeproj'
  experiments_pods
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
shared_targets = %w[Storage Networking Yosemite Hardware]
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
    configuration.build_settings['VALID_ARCHS'] = '$(ARCHS_STANDARD_64_BIT)'
  end

  # Let Pods targets inherit deployment target from the app
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/4859
  # =====================================
  #
  installer.pods_project.targets.each do |target|
    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
      end
    end
    target.build_configurations.each do |configuration|
      pod_ios_deployment_target = Gem::Version.new(configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
      if pod_ios_deployment_target <= app_ios_deployment_target
        configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      end
    end
  end

  # Flag Alpha builds for Tracks
  # ============================
  installer.pods_project.targets.each do |target|
    next unless target.name == "Automattic-Tracks-iOS"
    target.build_configurations.each do |config|
      next unless config.name == "Release-Alpha"
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'ALPHA=1']
    end
  end
end
