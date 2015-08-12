Pod::Spec.new do |s|
  s.name             = 'Parse'
  s.version          = '1.8.0'
  s.license          =  { :type => 'Commercial', :text => "See https://www.parse.com/about/terms" }
  s.homepage         = 'https://www.parse.com/'
  s.summary          = 'Parse is a complete technology stack to power your app\'s backend.'
  s.authors          = 'Parse'

  s.source           = { :git => "https://github.com/ParsePlatform/Parse-SDK-iOS-OSX.git", :tag => s.version.to_s }

  s.platform = :ios
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Parse/*.{h,m}',
                   'Parse/Internal/**/*.{h,m}'
  s.public_header_files = 'Parse/*.h'
  s.resources = 'Parse/Resources/Localizable.strings'

  s.frameworks        = 'AudioToolbox',
                        'CFNetwork',
                        'CoreGraphics',
                        'CoreLocation',
                        'QuartzCore',
                        'Security',
                        'StoreKit',
                        'SystemConfiguration'
  s.weak_frameworks   = 'Accounts',
                        'Social'
  s.libraries        = 'z', 'sqlite3'

  s.dependency 'Bolts/Tasks', '>= 1.2.0'
end
