Pod::Spec.new do |s|
  s.name             = 'Parse'
  s.version          = '1.19.1'
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

    s.source_files = 'Parse/Parse/*.{h,m}',
                     'Parse/Parse/Internal/**/*.{h,m}'
    s.public_header_files = 'Parse/Parse/*.h'
    s.private_header_files = 'Parse/Parse/Internal/**/*.h'

    s.ios.exclude_files = 'Parse/Parse/Internal/PFMemoryEventuallyQueue.{h,m}'
    s.osx.exclude_files = 'Parse/Parse/PFNetworkActivityIndicatorManager.{h,m}',
                          'Parse/Parse/PFProduct.{h,m}',
                          'Parse/Parse/PFPurchase.{h,m}',
                          'Parse/Parse/Internal/PFAlertView.{h,m}',
                          'Parse/Parse/Internal/Product/**/*.{h,m}',
                          'Parse/Parse/Internal/Purchase/**/*.{h,m}',
                          'Parse/Parse/Internal/PFMemoryEventuallyQueue.{h,m}'
    s.tvos.exclude_files = 'Parse/Parse/PFNetworkActivityIndicatorManager.{h,m}',
                           'Parse/Parse/Internal/PFAlertView.{h,m}'
    s.watchos.exclude_files = 'Parse/Parse/PFNetworkActivityIndicatorManager.{h,m}',
                              'Parse/Parse/PFProduct.{h,m}',
                              'Parse/Parse/PFPurchase.{h,m}',
                              'Parse/Parse/PFPush.{h,m}',
                              'Parse/Parse/PFPush+Synchronous.{h,m}',
                              'Parse/Parse/PFPush+Deprecated.{h,m}',
                              'Parse/Parse/PFInstallation.{h,m}',
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

    s.dependency 'Bolts/Tasks', '1.9.1'
  end

  s.subspec 'FacebookUtils' do |s|
    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.public_header_files = 'ParseFacebookUtils/ParseFacebookUtils/*.h'
    s.source_files = 'ParseFacebookUtils/ParseFacebookUtils/**/*.{h,m}'
    s.exclude_files = 'ParseFacebookUtils/ParseFacebookUtils/ParseFacebookUtilsV4.h',
                      'ParseFacebookUtils/ParseFacebookUtils/Internal/AuthenticationProvider/tvOS/**/*.{h,m}'

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
    s.dependency 'Bolts/Tasks', '~> 1.9.1'
    s.dependency 'FBSDKLoginKit', '~> 9.x'
  end

  s.subspec 'FacebookUtils-tvOS' do |s|
    s.platform = :tvos
    s.tvos.deployment_target = '10.0'
    s.public_header_files = 'ParseFacebookUtils/ParseFacebookUtils/*.h'
    s.source_files = 'ParseFacebookUtils/ParseFacebookUtils/**/*.{h,m}'
    s.exclude_files = 'ParseFacebookUtils/ParseFacebookUtils/ParseFacebookUtilsV4.h',
                      'ParseFacebookUtils/ParseFacebookUtils/Internal/AuthenticationProvider/iOS/**/*.{h,m}'

    s.frameworks        = 'AudioToolbox',
                          'CFNetwork',
                          'CoreGraphics',
                          'CoreLocation',
                          'QuartzCore',
                          'Security',
                          'SystemConfiguration'
    s.libraries        = 'z', 'sqlite3'

    s.dependency 'Parse/Core'
    s.dependency 'Bolts/Tasks', '~> 1.9.1'
    s.dependency 'FBSDKTVOSKit', '~> 9.x'
    s.dependency 'FBSDKShareKit', '~> 9.x'
  end

  s.subspec 'TwitterUtils' do |s|
    s.platform = :ios
    s.public_header_files = 'ParseTwitterUtils/ParseTwitterUtils/*.h'
    s.source_files = 'ParseTwitterUtils/ParseTwitterUtils/**/*.{h,m}'
    s.exclude_files = 'ParseTwitterUtils/ParseTwitterUtils/ParseTwitterUtils.h'
    s.resource_bundle = { 'TwitterUtils' => 'ParseTwitterUtils/Resources/en.lproj' }
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
    s.source_files        = 'ParseUI/**/*.{h,m}'
    s.exclude_files = 'ParseUI/ParseUIDemo/**/*', 'ParseUI/Other/ParseUI.h', 'ParseUI/SignInWithAppleTests/'
    s.public_header_files = 'ParseUI/Classes/LogInViewController/*.h',
                            'ParseUI/Classes/SignUpViewController/*.h',
                            'ParseUI/Classes/QueryTableViewController/*.h',
                            'ParseUI/Classes/QueryCollectionViewController/*.h',
                            'ParseUI/Classes/ProductTableViewController/*.h',
                            'ParseUI/Classes/Views/*.h',
                            'ParseUI/Classes/Cells/*.h',
                            'ParseUI/Other/*.h'
    s.resource_bundles    = { 'ParseUI' => ['ParseUI/Resources/Localization/*.lproj'] }
    s.frameworks          = 'Foundation',
                            'UIKit',
                            'CoreGraphics',
                            'QuartzCore'
    s.dependency 'Parse/Core'
  end

  # prepare command for parseUI
  s.prepare_command     = <<-CMD
  ruby ParseUI/Scripts/convert_images.rb \
        ParseUI/Resources/Images/ \
        ParseUI/Generated/PFResources
  CMD
end
