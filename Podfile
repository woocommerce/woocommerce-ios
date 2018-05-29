source 'https://github.com/CocoaPods/Specs.git'

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
  pod 'Gridicons', '0.15'
  pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => '58ed623'

  # External Libraries
  # ==================
  #
  pod 'Crashlytics', '3.10.1'

end


# Networking!
# ===========
#
target 'Networking' do
  project 'Networking/Networking.xcodeproj'

  # External Libraries
  # ==================
  #
  pod 'Alamofire', '4.7.2'

  target 'NetworkingTests' do
    inherit! :search_paths
  end
end
