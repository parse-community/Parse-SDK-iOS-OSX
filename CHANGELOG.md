# Parse-SDK-iOS-OSX Changelog

### master
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.3...master)
* _Contributing to this repo? Add info about your change here to be included in next release_

### 1.18.0
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.2...1.17.3)

- FIX: Removed using NSURLCache in Catalyst. @toto @mman 
- NEW: Add get and set server functions. @mtrezza 
- NEW: Parse is now compatible with Swift 5. @noobs2ninjas 
- NEW: Updated project build targets to work with Catalyst. @noobs2ninjas 
- NEW: Parse as well as its dependencies are now compatible with macOS 10.15. @mman 
- FIX: Unit testing and nightly builds.
- FIX: ParseUI minimum api version should be iOS 8.0. Project settings and info.plist updated to reflect to fix Carthage builds. 
@noobs2ninjas, @drdaz, and @acinader did some hard work to not only update build environments to use Xcode 11 but also made necessary changes to get nightly builds to work on both Travis and CircleCI. This will allow us to resume more consistent updates again. 
 
NEWS: After getting on contact with BoltsFramework maintainers at Facebook they have allowed us to get changes in to fix app store declines due to  


### 1.17.3
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.2...1.17.3)

- FIX: Updates xcbuildtools submodule ([#1365](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1365)), thanks to [Darren Black](https://github.com/drdaz)
- FIX: Bandaid for Crashlytics [#944](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/944) ([#1376](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1376)), thanks to [Rogers George](https://github.com/ceramicatheist)
- NEW: tvOS push support ([#1375](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1375)), thanks to [Thomas Kollbach](https://github.com/toto)
- FIX: Class properties ([#1400](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1400)), thanks to [Thomas Kollbach](https://github.com/toto)
- FIX: Upgrade ParseFacebookUtils dependency to Facebook SDK v5.x ([#1424](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1424)) thanks to [Herrick Wolber](https://github.com/rico237) and [Darren Black](https://github.com/drdaz)
