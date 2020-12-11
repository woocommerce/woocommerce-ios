source 'https://cdn.cocoapods.org/'

unless ['BUNDLE_BIN_PATH', 'BUNDLE_GEMFILE'].any? { |k| ENV.key?(k) }
  raise 'Please run CocoaPods via `bundle exec`'
end

inhibit_all_warnings!
use_frameworks! # Defaulting to use_frameworks! See pre_install hook below for static linking.
use_modular_headers!

app_ios_deployment_target = Gem::Version.new('13.0')

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

  # Use the latest bugfix for coretelephony
  #pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :branch => 'add/application-state-tag'
  pod 'Automattic-Tracks-iOS', '~> 0.6.0'

  pod 'Gridicons', '~> 1.0'

  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  # pod 'WordPressAuthenticator', '~> 1.31.0-beta.4'
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => ''
  pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => 'fix/540-site-address-button'
  # pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'

  pod 'WordPressShared', '~> 1.12'

  pod 'WordPressUI', '~> 1.7.2'
  # pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :branch => ''

  aztec

  pod 'WPMediaPicker', '~> 1.7.1'

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
  pod 'Kingfisher', '~> 5.11.0'
  pod 'Wormholy', '~> 1.6.2', :configurations => ['Debug']

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
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'

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

  pod 'Sourcery', '~> 0.18', :configuration => 'Debug'

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

# Workarounds:
# ============
#

# Static Frameworks:
# ============
#
# Make all pods that are not shared across multiple targets into static frameworks by overriding the static_framework? function to return true
# Linking the shared frameworks statically would lead to duplicate symbols
# A future version of CocoaPods may make this easier to do. See https://github.com/CocoaPods/CocoaPods/issues/7428
shared_targets = ['Storage', 'Networking', 'Yosemite']
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
    def pod.static_framework?;
      true
    end
  end

  puts "Installing #{static.count} pods as static frameworks"
  puts "Installing #{dynamic.count} pods as dynamic frameworks"

  # Force CocoaLumberjack Swift version
  installer.analysis_result.specifications.each do |s|
    if s.name == 'CocoaLumberjack'
      s.swift_version = '5.0'
    end
  end
end

post_install do |installer|

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
      target.build_configurations.each do |configuration|
         pod_ios_deployment_target = Gem::Version.new(configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
         configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET' if pod_ios_deployment_target <= app_ios_deployment_target
      end
  end
end

