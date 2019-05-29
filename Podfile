inhibit_all_warnings!
use_frameworks!

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
  pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :branch => 'develop'

  pod 'Gridicons', '~> 0.18'
  
  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  #pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => 'task/wc-support-site-url-login'
  pod 'WordPressAuthenticator', '~> 1.4.0'

  # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :branch => 'task/support-swift-5'  
  pod 'WordPressShared', '~> 1.7'
  
  pod 'WordPressUI', '~> 1.2'


  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.7'
  pod 'KeychainAccess', '~> 3.2'
  pod 'CocoaLumberjack', '~> 3.5'
  pod 'CocoaLumberjack/Swift', '~> 3.5'
  pod 'XLPagerTabStrip', '~> 9.0'
  pod 'Charts', '~> 3.2'
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
pre_install do |installer|
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
