inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'
workspace 'WooCommerce.xcworkspace'



# Main Target!
# ============
#
target 'WooCommerce' do
  project 'WooCommerce/WooCommerce.xcodeproj'


  # Automattic Libraries
  # ====================
  #
  pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.2.3'
  pod 'Gridicons', '0.16'
  pod 'WordPressAuthenticator', '1.1.0-beta.1'
  pod 'WordPressShared', '1.1.1-beta.2'
  pod 'WordPressUI', '~> 1.0'


  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.7'
  pod 'Crashlytics', '~> 3.10'
  pod 'KeychainAccess', '~> 3.1'
  pod 'CocoaLumberjack', '~> 3.4'
  pod 'XLPagerTabStrip', '~> 8.0'
  pod 'Charts', '~> 3.2'

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
target 'Yosemite' do
  project 'Yosemite/Yosemite.xcodeproj'

  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.7'
  pod 'CocoaLumberjack', '~> 3.4'

  # Unit Tests
  # ==========
  #
  target 'YosemiteTests' do
    inherit! :search_paths
  end

end



# Networking Layer:
# =================
#
target 'Networking' do
  project 'Networking/Networking.xcodeproj'


  # External Libraries
  # ==================
  #
  pod 'Alamofire', '~> 4.7'
  pod 'CocoaLumberjack', '~> 3.4'


  # Unit Tests
  # ==========
  #
  target 'NetworkingTests' do
    inherit! :search_paths
  end
end


# Storage Layer:
# ==============
#
target 'Storage' do
  project 'Storage/Storage.xcodeproj'

  # External Libraries
  # ==================
  #
  pod 'CocoaLumberjack', '~> 3.4'


  # Unit Tests
  # ==========
  #
  target 'StorageTests' do
    inherit! :search_paths
  end
end



# Workarounds:
# ============
#
post_install do |installer|

  # Workaround: SWIFT_VERSION = 4.0 in dependencies that need it
  # ============================================================
  #
  # TODO: Remove as soon as the dependencies get updated!
  #
  installer.pods_project.targets.each do |target|
      if ['XLPagerTabStrip'].include? target.name
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '4.0'
          end
      end
  end

  # Workaround: Drop 32 Bit Architectures
  # =====================================
  #
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['VALID_ARCHS'] = '$(ARCHS_STANDARD_64_BIT)'
  end
end
