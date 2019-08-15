inhibit_all_warnings!
use_frameworks! # Defaulting to use_frameworks! See pre_install hook below for static linking.
use_modular_headers!

platform :ios, '12.0'
workspace 'WooCommerce.xcworkspace'

plugin 'cocoapods-repo-update'

# Main Target!
# ============
#
target 'WooCommerce' do
  project 'WooCommerce/WooCommerce.xcodeproj'


  # Automattic Libraries
  # ====================
  #

  # Use the latest bugfix for coretelephony
  #pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.2.4-beta.1'
  pod 'Automattic-Tracks-iOS', '~> 0.4.0'

  pod 'Gridicons', '~> 0.18'
  
  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  #pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => 'task/wc-support-site-url-login'
  pod 'WordPressAuthenticator', '~> 1.5.2'

  # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :branch => 'task/support-swift-5'  
  pod 'WordPressShared', '~> 1.8.2'
  
  pod 'WordPressUI', '~> 1.3.5-beta'


  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.7'
  pod 'KeychainAccess', '~> 3.2'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
  pod 'XLPagerTabStrip', '~> 9.0'
  pod 'Charts', '~> 3.3.0'
  pod 'ZendeskSDK', '~> 2.3.1'

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
  pod 'Alamofire', '~> 4.7'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
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
  pod 'Alamofire', '~> 4.7'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
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
end
