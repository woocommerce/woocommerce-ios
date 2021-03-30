# For security reasons, please always keep the wordpress-mobile source first and the CDN second.
# For more info, see https://github.com/wordpress-mobile/cocoapods-specs#source-order-and-security-considerations
install! 'cocoapods', warn_for_multiple_pod_sources: false
source 'https://github.com/wordpress-mobile/cocoapods-specs.git'
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

## Flipper (https://fbflipper.com/docs/getting-started/ios-native)
## ===================================
##
def flipper
  flipperkit_version = '0.49.0'

  # It is likely that you'll only want to include Flipper in debug builds,
  # in which case you add the `:configuration` directive:
  pod 'FlipperKit', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitLayoutComponentKitSupport', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/SKIOSNetworkPlugin', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitUserDefaultsPlugin', '~>' + flipperkit_version, :configuration => 'Debug'
  # ...unfortunately at this time that means you'll need to explicitly mark
  # transitive dependencies as being for debug build only as well:
  pod 'Flipper-DoubleConversion', :configuration => 'Debug'
  pod 'Flipper-Folly', :configuration => 'Debug'
  pod 'Flipper-Glog', :configuration => 'Debug'
  pod 'Flipper-PeerTalk', :configuration => 'Debug'
  pod 'CocoaLibEvent', :configuration => 'Debug'
  pod 'boost-for-react-native', :configuration => 'Debug'
  pod 'OpenSSL-Universal', :configuration => 'Debug'
  pod 'CocoaAsyncSocket', :configuration => 'Debug'
  # ...except, of course, those transitive dependencies that your
  # application itself depends, e.g.:
  pod 'ComponentKit', '~> 0.30', :configuration => 'Debug'


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
  pod 'WordPressAuthenticator', '~> 1.36.0-beta'
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => ''
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => ''
  # pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'

  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  pod 'WordPressKit', '~> 4.26.0'

  pod 'WordPressShared', '~> 1.15'

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
  pod 'Wormholy', '~> 1.6.4', :configurations => ['Debug']

  flipper

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

  pod 'Sourcery', '~> 1.0.3', :configuration => 'Debug'

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

# If you use `use_frameworks!` in your Podfile,
# uncomment the below $static_framework array and also
# the pre_install section.  This will cause Flipper and
# it's dependencies to be built as a static library and all other pods to
# be dynamic.
#
# NOTE Doing this may lead to a broken build if any of these are also
#      transitive dependencies of other dependencies and are expected
#      to be built as frameworks.
#
$static_framework = ['FlipperKit', 'Flipper', 'Flipper-Folly',
  'CocoaAsyncSocket', 'ComponentKit', 'Flipper-DoubleConversion',
  'Flipper-Glog', 'Flipper-PeerTalk', 'Flipper-RSocket', 'Yoga', 'YogaKit',
  'CocoaLibEvent', 'OpenSSL-Universal', 'boost-for-react-native']

pre_install do |installer|
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
  installer.pod_targets.each do |pod|
      if $static_framework.include?(pod.name)
        def pod.build_type;
          Pod::BuildType.static_library
        end
      end
    end
end

