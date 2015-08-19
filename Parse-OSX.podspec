Pod::Spec.new do |s|
  s.deprecated_in_favor_of = 'Parse'
  
  s.name              = 'Parse-OSX'
  s.version           = '1.8.1'
  s.license           =  { :type => 'Commercial', :text => "See https://www.parse.com/about/terms" }
  s.homepage          = 'https://www.parse.com/'
  s.summary           = 'Parse is a complete technology stack to power your app\'s backend.'
  s.documentation_url = 'https://parse.com/docs/ios_guide'
  s.authors           = 'Parse'

  s.source           = { :git => "https://github.com/ParsePlatform/Parse-SDK-iOS-OSX.git", :tag => s.version.to_s }

  s.platform = :osx
  s.osx.deployment_target = '10.9'
  s.requires_arc = true
  
  s.header_dir = 'Parse'
  s.module_name = 'Parse'
  
  s.source_files = 'Parse/*.{h,m}',
                   'Parse/Internal/**/*.{h,m}'
  s.public_header_files = 'Parse/*.h'
  s.resources = 'Parse/Resources/en.lproj'
  s.exclude_files = 'Parse/PFNetworkActivityIndicatorManager.{h,m}',
                    'Parse/PFProduct.{h,m}',
                    'Parse/PFPurchase.{h,m}',
                    'Parse/Internal/PFAlertView.{h,m}',
                    'Parse/Internal/Product/**/*.{h,m}',
                    'Parse/Internal/Purchase/**/*.{h,m}'

  s.frameworks        = 'ApplicationServices',
                        'CFNetwork',
                        'CoreGraphics',
                        'CoreLocation',
                        'QuartzCore',
                        'Security',
                        'SystemConfiguration'
  s.libraries        = 'z', 'sqlite3'

  s.dependency 'Bolts/Tasks', '>= 1.2.0'
end
