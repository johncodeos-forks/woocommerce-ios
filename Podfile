source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!
use_frameworks! # Defaulting to use_frameworks! See pre_install hook below for static linking.
use_modular_headers!

platform :ios, '12.0'
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
  pod 'Automattic-Tracks-iOS', '~> 0.5.1'

  pod 'Gridicons', '~> 1.0'

  # To allow pod to pick up beta versions use -beta. E.g., 1.1.7-beta.1
  pod 'WordPressAuthenticator', '~> 1.26.0'
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => ''
  # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => ''
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
  pod 'Charts', '~> 3.3.0'
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

  # Hide Xcode 12 iPhone deployment warnings for now.
  #
  # Here's an example warning:
  #
  # ```
  # The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0,
  # but the range of supported deployment target versions is 9.0 to 14.0.99.
  # ```
  #
  # We can remove this once we've upgraded the Pod libraries that are causing the warnings.
  #
  # Ref: https://github.com/CocoaPods/CocoaPods/issues/9884#issuecomment-699828314
  #
  targets_and_configs_to_fix = installer.pods_project.targets.reduce({}) do |result, target|
    configs_to_fix = target.build_configurations.filter do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] == '8.0'
    end

    result[target] = configs_to_fix unless configs_to_fix.empty?
    result
  end

  targets_and_configs_to_fix.each do |target, configs|
    configs.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
    end
  end

  unless targets_and_configs_to_fix.empty?
    target_names = targets_and_configs_to_fix.keys.map(&:name)
    puts "\n⚠️  Changed deployment targets of these libraries to hide Xcode 12 build warnings: #{target_names.join(', ')}.\n\n"
  end
end
