# Parse-SDK-iOS-OSX Changelog

### master
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.1...master)
* _Contributing to this repo? Add info about your change here to be included in next release_

### 1.19.1
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.0...1.19.1)

__Improvements__
- Allow SDK to build for Mac Catalyst ([#1543](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1543)), thanks to [Martin Mann](https://github.com/mman).

__Fixes__
- Pass user details from Sign In With Apple to user ([#1551](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1551)), thanks to [Darren Black](https://github.com/drdaz).
- Bolts compilation error in Xcode 12 ([#1548](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1548)), thanks to [Derek Lee](https://github.com/derekleerock).
- App Store submission failed for MinimumOSVersion ([#1515](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1515)), thanks to [Manuel Trezza](https://github.com/mtrezza).

### 1.19.0
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.18.0...1.19.0)

__New features__
- Added Sign In With Apple support to ParseUI ([#1475](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1475)), thanks to [Darren Black](https://github.com/drdaz).
- Transparent icons ([#1530](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1530)), thanks to [Donald Ness](https://github.com/programmarchy).

__Improvements__
- Updated Facebook SDK to 6.x ([#1504](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1504)), thanks to [Markus Winkler](https://github.com/markuswinkler).

__Fixes__
- Removes deprecated UIWebView usage ([#1511](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1511)), thanks to [Nathan Kellert](https://github.com/parse-community/Parse-SDK-iOS-OSX/commits?author=noobs2ninjas).
- Fixes building with Xcode 12 ([#1527](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1527)), thanks to [Steffen Matthischke](https://github.com/HeEAaD).


### 1.18.0
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.3...1.18.0)

__New features__
- Add get and set server functions ([#1464](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1464)), thanks to [Manuel Trezza](https://github.com/mtrezza).

__Improvements__
- Swift 5 compatibility ([#1451](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1451)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas).
- macOS 10.15 compatibility ([#1460](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1460)), thanks to [Martin Man](https://github.com/mman).

__Fixes__
- Removed using NSURLCache in Catalyst ([#1469](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1489)), thanks to [Thomas Kollbach](https://github.com/toto) and [Martin Man](https://github.com/mman).
- Updated project build targets to work with Catalyst ([#1473](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1473)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas).
- ParseUI minimum api version should be iOS 8.0 ([#1494](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1473)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas).
- Removed `iPhoneSimulator` from `CFBundleSupportedPlatforms` ([#1496](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1496), [#1497](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1497)), thanks to [Tom Fox](https://github.com/TomWFox).

[Nathan Kellert](https://github.com/noobs2ninjas) and [Darren Black](https://github.com/drdaz) did some hard work to not only update build environments to use Xcode 11 but also made necessary changes to get nightly builds to work on both Travis and CircleCI. This will allow us to resume more consistent updates again. [Arthur Cinader](https://github.com/acinader) helped with Travis release build fixes.

 - Fixed CircleCI Nightly Build and adding extra PR Testing [#1490](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1490).
 - Fixed tvOS builds [#1489](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1489).
 - Added OCMock manually to CircleCI Build [#1490](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1490).
 - Updated Travis and CircleCI build environments [#1473](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1473).
 
#### Notice
After getting in contact with the Bolts Framework maintainers from Facebook they have allowed us to get changes in to fix app store declines due to still using UIWebView(iOS only) rather than updating to WKWebView(iOS, macOS, and iPad OS compatible). Those that got declined should be able to re-submit after updating to the latest version of this SDK as well as its dependencies. 


### 1.17.3
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.2...1.17.3)

__New Features__
- tvOS push support ([#1375](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1375)), thanks to [Thomas Kollbach](https://github.com/toto).

__Fixes__
- Update xcbuildtools submodule ([#1365](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1365)), thanks to [Darren Black](https://github.com/drdaz).
- Bandaid for Crashlytics [#944](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/944) ([#1376](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1376)), thanks to [Rogers George](https://github.com/ceramicatheist).
- Fix Class properties ([#1400](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1400)), thanks to [Thomas Kollbach](https://github.com/toto).
- Upgrade ParseFacebookUtils dependency to Facebook SDK v5.x ([#1424](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1424)) thanks to [Herrick Wolber](https://github.com/rico237) and [Darren Black](https://github.com/drdaz).
