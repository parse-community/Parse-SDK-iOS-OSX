Pod::Spec.new do |s|
  s.name             = 'Parse'
  s.version          = '1.19.4'
  s.license          =  { :type => 'BSD', :file => 'LICENSE' }
  s.homepage         = 'http://parseplatform.org/'
  s.summary          = 'A library that gives you access to the powerful Parse cloud platform from your iOS/OS X/watchOS/tvOS app.'
  s.authors          = 'Parse Community'
  s.social_media_url = 'https://twitter.com/ParsePlatform'

  s.source           = { :git => 'https://github.com/parse-community/Parse-SDK-iOS-OSX.git', :tag => s.version.to_s }

  s.platform = :ios, :osx, :tvos, :watchos
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '2.0'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |s|
    s.requires_arc = true

    s.source_files = 'Parse/Parse/Source/*.{h,m}',
                     'Parse/Parse/Internal/**/*.{h,m}'
    s.public_header_files = 'Parse/Parse/Source/*.h'
    s.private_header_files = 'Parse/Parse/Internal/**/*.h'

    s.ios.exclude_files = 'Parse/Parse/Internal/PFMemoryEventuallyQueue.{h,m}'
    s.osx.exclude_files = 'Parse/Parse/Source/PFNetworkActivityIndicatorManager.{h,m}',
                          'Parse/Parse/Source/PFProduct.{h,m}',
                          'Parse/Parse/Source/PFPurchase.{h,m}',
                          'Parse/Parse/Internal/PFAlertView.{h,m}',
                          'Parse/Parse/Internal/Product/**/*.{h,m}',
                          'Parse/Parse/Internal/Purchase/**/*.{h,m}',
                          'Parse/Parse/Internal/PFMemoryEventuallyQueue.{h,m}'
    s.tvos.exclude_files = 'Parse/Parse/Source/PFNetworkActivityIndicatorManager.{h,m}',
                           'Parse/Parse/Internal/PFAlertView.{h,m}'
    s.watchos.exclude_files = 'Parse/Parse/Source/PFNetworkActivityIndicatorManager.{h,m}',
                              'Parse/Parse/Source/PFProduct.{h,m}',
                              'Parse/Parse/Source/PFPurchase.{h,m}',
                              'Parse/Parse/Source/PFPush.{h,m}',
                              'Parse/Parse/Source/PFPush+Synchronous.{h,m}',
                              'Parse/Parse/Source/PFPush+Deprecated.{h,m}',
                              'Parse/Parse/Source/PFInstallation.{h,m}',
                              'Parse/Parse/Internal/PFAlertView.{h,m}',
                              'Parse/Parse/Internal/PFReachability.{h,m}',
                              'Parse/Parse/Internal/Product/**/*.{h,m}',
                              'Parse/Parse/Internal/Purchase/**/*.{h,m}',
                              'Parse/Parse/Internal/Push/**/*.{h,m}',
                              'Parse/Parse/Internal/Installation/Controller/*.{h,m}',
                              'Parse/Parse/Internal/Installation/Constants/*.{h,m}',
                              'Parse/Parse/Internal/Installation/CurrentInstallationController/*.{h,m}',
                              'Parse/Parse/Internal/Installation/PFInstallationPrivate.h',
                              'Parse/Parse/Internal/Commands/PFRESTPushCommand.{h,m}',
                              'Parse/Parse/Internal/PFMemoryEventuallyQueue.{h,m}'

    s.resource_bundle = { 'Parse' => 'Parse/Parse/Resources/en.lproj' }

    s.ios.frameworks = 'AudioToolbox',
                       'CFNetwork',
                       'CoreGraphics',
                       'CoreLocation',
                       'QuartzCore',
                       'Security',
                       'StoreKit',
                       'SystemConfiguration'
    s.ios.weak_frameworks = 'Accounts',
                            'Social'
    s.osx.frameworks = 'ApplicationServices',
                       'CFNetwork',
                       'CoreGraphics',
                       'CoreLocation',
                       'QuartzCore',
                       'Security',
                       'SystemConfiguration'
    s.tvos.frameworks = 'CoreLocation',
                        'StoreKit',
                        'SystemConfiguration',
                        'Security'

    s.libraries        = 'z', 'sqlite3'

    s.dependency 'Bolts/Tasks', '1.9.2'
  end

  s.subspec 'FacebookUtils' do |s|
    s.platform = :ios, :tvos
    s.ios.deployment_target = '12.0'
    s.tvos.deployment_target = '12.0'
    s.public_header_files = 'ParseFacebookUtils/ParseFacebookUtils/Source/*.h'
    s.source_files = 'ParseFacebookUtils/ParseFacebookUtils/Source/*.{h,m}'

    s.frameworks        = 'AudioToolbox',
                          'CFNetwork',
                          'CoreGraphics',
                          'CoreLocation',
                          'QuartzCore',
                          'Security',
                          'SystemConfiguration'
    s.ios.weak_frameworks = 'Accounts',
                            'Social'
    s.libraries        = 'z', 'sqlite3'

    s.dependency 'Parse/Core'
    s.dependency 'Bolts/Tasks', '1.9.2'
    s.dependency 'FBSDKCoreKit', '= 15.1.0'
    s.dependency 'FBSDKLoginKit', '= 15.1.0'
  end

  s.subspec 'FacebookUtils-iOS' do |s|
    s.platform = :ios
    s.ios.deployment_target = '12.0'
    s.public_header_files = 'ParseFacebookUtilsiOS/ParseFacebookUtilsiOS/Source/*.h'
    s.private_header_files = 'ParseFacebookUtilsiOS/ParseFacebookUtilsiOS/Internal/**/*.h'
    s.source_files = 'ParseFacebookUtilsiOS/ParseFacebookUtilsiOS/Source/*.{h,m}',
                     'ParseFacebookUtilsiOS/ParseFacebookUtilsiOS/Internal/**/*.{h,m}'

    s.frameworks        = 'AudioToolbox',
                          'CFNetwork',
                          'CoreGraphics',
                          'CoreLocation',
                          'QuartzCore',
                          'Security',
                          'SystemConfiguration'
    s.ios.weak_frameworks = 'Accounts',
                            'Social'
    s.libraries        = 'z', 'sqlite3'

    s.dependency 'Parse/Core'
    s.dependency 'Parse/FacebookUtils'
    s.dependency 'Bolts/Tasks', '1.9.2'
    s.dependency 'FBSDKCoreKit', '= 15.1.0'
    s.dependency 'FBSDKLoginKit', '= 15.1.0'
  end

  s.subspec 'FacebookUtils-tvOS' do |s|
    s.platform = :tvos
    s.tvos.deployment_target = '12.0'
    s.public_header_files = 'ParseFacebookUtilsTvOS/ParseFacebookUtilsTvOS/Source/*.h'
    s.private_header_files = 'ParseFacebookUtilsTvOS/ParseFacebookUtilsTvOS/Internal/*.h'
    s.source_files = 'ParseFacebookUtilsTvOS/ParseFacebookUtilsTvOS/Source/*.{h,m}',
                     'ParseFacebookUtilsTvOS/ParseFacebookUtilsTvOS/Internal/*.{h,m}'

    s.frameworks        = 'AudioToolbox',
                          'CFNetwork',
                          'CoreGraphics',
                          'CoreLocation',
                          'QuartzCore',
                          'Security',
                          'SystemConfiguration'
    s.libraries        = 'z', 'sqlite3'

    s.dependency 'Parse/Core'
    s.dependency 'Parse/FacebookUtils'
    s.dependency 'Bolts/Tasks', '1.9.2'
    s.dependency 'FBSDKTVOSKit', '= 15.1.0'
    s.dependency 'FBSDKShareKit', '= 15.1.0'
  end

  s.subspec 'TwitterUtils' do |s|
    s.platform = :ios
    s.public_header_files = 'ParseTwitterUtils/ParseTwitterUtils/Source/*.h'
    s.source_files = 'ParseTwitterUtils/ParseTwitterUtils/Source/*.{h,m}',
                     'ParseTwitterUtils/ParseTwitterUtils/Internal/**/*.{h,m}'
    s.private_header_files = 'ParseTwitterUtils/ParseTwitterUtils/Internal/**/*.h'
    s.resource_bundle = { 'TwitterUtils' => 'ParseTwitterUtils/ParseTwitterUtils/Resources/en.lproj' }
    s.frameworks        = 'AudioToolbox',
                          'CFNetwork',
                          'CoreGraphics',
                          'CoreLocation',
                          'QuartzCore',
                          'Security',
                          'StoreKit',
                          'SystemConfiguration'
    s.weak_frameworks = 'Accounts',
                        'Social'
    s.libraries        = 'z', 'sqlite3'
    s.dependency 'Parse/Core'
  end

  s.subspec 'UI' do |s|
    s.platform              = :ios
    s.requires_arc          = true
    s.ios.deployment_target = '9.0'
    s.source_files        = 'ParseUI/ParseUI/Internal/**/*.{h,m}',
                            'ParseUI/ParseUI/Source/*.{h,m}'
    s.exclude_files = 'ParseUI/ParseUIDemo/**/*', 'ParseUI/SignInWithAppleTests/'
    s.public_header_files = 'ParseUI/ParseUI/Source/*.h'
    s.private_header_files = 'ParseUI/ParseUI/Internal/**/*.h'
    s.resource_bundles    = { 'ParseUI' => ['ParseUI/ParseUI/Resources/Localization/*.lproj'] }
    s.frameworks          = 'Foundation',
                            'UIKit',
                            'CoreGraphics',
                            'QuartzCore'
    s.dependency 'Parse/Core'
  end

  # prepare command for parseUI
  s.prepare_command     = <<-CMD
  ruby ParseUI/Scripts/convert_images.rb \
        ParseUI/ParseUI/Resources/Images/ \
        ParseUI/Source/PFResources
  CMD
end
