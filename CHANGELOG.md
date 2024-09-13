## [4.1.1](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/4.1.0...4.1.1) (2024-07-15)


### Bug Fixes

* SPM build issues with Xcode 16 ([#1795](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1795)) ([5381325](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/5381325fae622eaa5292146ea322a00c0f46e97d))

# [4.1.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/4.0.1...4.1.0) (2024-06-17)


### Features

* Add idempotency ([#1790](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1790)) ([dcdf457](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/dcdf45743eab1126a76aba34e555fb2575f67a3b))

## [4.0.1](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/4.0.0...4.0.1) (2024-04-28)


### Bug Fixes

* LiveQuery starter project fails to build ([#1784](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1784)) ([0821194](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/08211940c839b8b9896d715891795049a6378766))

# [4.0.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/3.0.0...4.0.0) (2024-04-28)


### Features

* Remove `ParseUI` ([#1783](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1783)) ([139eca7](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/139eca7f2423bf92c5b6d821eaf4cda16816dd6f))


### BREAKING CHANGES

* This release removes `ParseUI`. ([139eca7](139eca7))

# [3.0.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.7.3...3.0.0) (2024-04-08)


### Features

* Add `PFObject.isDataAvailableForKey` to check if data is available for individual key ([#1756](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1756)) ([dd05d41](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/dd05d411a54712ee927e5fb8af390ae36a60ed7e))
* Remove `ParseFacebookUtils` and `ParseTwitterUtils` ([#1779](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1779)) ([f1311ee](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/f1311eee00a2419720e85d7ca90fe868e509e4ed))


### BREAKING CHANGES

* Removes convenience modules `ParseFacebookUtils` and `ParseTwitterUtils`, instead manually add the 3rd party authentication service SDK to log in and provide the authentication data to `PFUser.logInWithAuthType` to link the Parse User. ([f1311ee](f1311ee))

## [2.7.3](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.7.2...2.7.3) (2023-10-06)


### Bug Fixes

* Compilation errors in `ParseLiveQuery` using `Starscream` 4.0.6 ([#1749](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1749)) ([3da5bde](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/3da5bde7d20ac4ff99aa40dd75fa8f7f3997acae))

## [2.7.2](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.7.1...2.7.2) (2023-10-05)


### Bug Fixes

* Compilation errors `Undefined symbol` and `SystemConfiguration not found` on watchOS ([#1748](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1748)) ([e7df36b](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/e7df36beb735fd7dc4b86127bf86b34fb30b009d))

### Notes

- The compiled frameworks of the Parse SDK will not be provided anymore as part of a release. Instead use Swift Package Manager to add the Parse SDK to your Xcode project.

## [2.7.1](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.7.0...2.7.1) (2023-09-30)


### Bug Fixes

* Compilation error on macOS `Undefined symbol: OBJC_CLASS$_PFProductsRequestHandler` ([#1739](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1739)) ([7231bf7](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/7231bf77fb5dd74e05c19c7a67ba61840c43768b))

# [2.7.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.6.0...2.7.0) (2023-07-20)


### Features

* Add support for `PFQuery.containedBy` ([#1735](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1735)) ([2316a3f](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/2316a3f47f2b19a73bc4a684cefa082cbc2d53d1))

# [2.6.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.5.0...2.6.0) (2023-07-14)


### Features

* Add support for compound AND queries with `PFQuery.andQueryWithSubqueries` ([#1733](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1733)) ([bd09fe4](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/bd09fe446748d26c0e91879fa3cd67e0eb4b5c1b))

# [2.5.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.4.0...2.5.0) (2023-07-14)


### Features

* Add support to include all pointers with `PFQuery.includeAll` ([#1734](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1734)) ([04f81e8](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/04f81e803ae679c96e3f37cfe0e0954ea1c210bf))

# [2.4.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.3.0...2.4.0) (2023-07-11)


### Features

* Add support to exclude `PFObject` fields in query results with `PFQuery.excludeKeys` ([#1731](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1731)) ([98e5faf](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/98e5faf5d0b5eb8761bad1b37458d698262b18ce))

# [2.3.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.2.0...2.3.0) (2023-06-08)


### Features

* Add LiveQuery module to SDK; this deprecates the separate [Parse LiveQuery SDK](https://github.com/parse-community/ParseLiveQuery-iOS-OSX) ([#1712](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1712)) ([154da34](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/154da34b021abf4f53fa632539505e18b4cf3e8d))

# [2.2.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.1.1...2.2.0) (2023-03-10)


### Features

* Add support for `PFQuery.explain` and `PFQuery.hint` ([#1723](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1723)) ([583d266](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/583d2662c05b871bfda75cf6e44608e903b544a2))

## [2.1.1](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.1.0...2.1.1) (2023-02-26)


### Performance Improvements

* Skip registering auth delegate if it's already registered ([#1715](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1715)) ([6d7eadd](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/6d7eadd322d3ac2f011c33d9dbee89b9e051e744))

# [2.1.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.0.3...2.1.0) (2023-02-22)


### Features

* Add `PFUser.unregisterAuthenticationDelegate` and allow to register delegate gracefully if another delegate is already registered ([#1711](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1711)) ([0ef9351](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/0ef93517136d668991b0226643e06bb15982935c))

## [2.0.3](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.0.2...2.0.3) (2023-02-20)


### Bug Fixes

* `Parse.setServer` does not set new server URL ([#1708](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1708)) ([fd487da](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/fd487da490d7a3ad3f49c86ffde28973d7ef7f71))

## [2.0.2](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.0.1...2.0.2) (2023-01-30)


### Bug Fixes

* MacOS command line app crashes if Parse framework is installed in `/Library/Frameworks/` ([#1395](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1395)) ([54bc6f3](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/54bc6f3967fad8b8febe35932ce2024ba6928174))

## [2.0.1](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/2.0.0...2.0.1) (2023-01-30)


### Bug Fixes

* Adding via SPM doesn't work due to unstable Bolts dependency ([#1695](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1695)) ([b264df1](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/b264df19e06a928daa222cf34fbe07b1ed51aed9))

# [2.0.0](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.4...2.0.0) (2023-01-29)


### Features

* Add Swift Package Manager support; upgrade `ParseFacbookUtils` to Facebook SDK 15 ([#1683](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1683)) ([840390b](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/840390b18c8e567356103d9ff19ca21523c16ac3))


### BREAKING CHANGES

* Carthage support is removed; the core module name has changed therefore the import statement is now `import ParseCore` instead of `import Parse` (#1683) ([840390b](840390b))

## [1.19.4](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.3...1.19.4) (2022-10-26)


### Bug Fixes

* implementation via CocoaPods fails due to missing `FBSDKCoreKit` dependency ([#1666](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1666)) ([ac8a4fa](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/ac8a4fade08c2be59d7ece014ba429067f598deb))

## [1.19.3](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.2...1.19.3) (2021-11-21)


### Bug Fixes

* compilation errors with Xcode 13 ([#1619](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1619)) ([99ff6ec](https://github.com/parse-community/Parse-SDK-iOS-OSX/commit/99ff6ec64ee65b1a60946ea69e4d8039c1c5ae16))

# 1.19.2
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.1...1.19.2)

__Improvements__
- Updates Facebook SDK to 9.x ([#1599](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1599)), thanks to [kmaker](https://github.com/kmaker).

__Fixes__
- Crash in Twitter login flow ([#1566](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1567)), thanks to [dhana](https://github.com/dsp1589).

# 1.19.1
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.19.0...1.19.1)

__Improvements__
- Allow SDK to build for Mac Catalyst ([#1543](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1543)), thanks to [Martin Mann](https://github.com/mman).

__Fixes__
- Pass user details from Sign In With Apple to user ([#1551](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1551)), thanks to [Darren Black](https://github.com/drdaz).
- Bolts compilation error in Xcode 12 ([#1548](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1548)), thanks to [Derek Lee](https://github.com/derekleerock).
- App Store submission failed for MinimumOSVersion ([#1515](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1515)), thanks to [Manuel Trezza](https://github.com/mtrezza).

# 1.19.0
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.18.0...1.19.0)

__New features__
- Added Sign In With Apple support to ParseUI ([#1475](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1475)), thanks to [Darren Black](https://github.com/drdaz).
- Transparent icons ([#1530](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1530)), thanks to [Donald Ness](https://github.com/programmarchy).

__Improvements__
- Updated Facebook SDK to 6.x ([#1504](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1504)), thanks to [Markus Winkler](https://github.com/markuswinkler).

__Fixes__
- Removes deprecated UIWebView usage ([#1511](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1511)), thanks to [Nathan Kellert](https://github.com/parse-community/Parse-SDK-iOS-OSX/commits?author=noobs2ninjas).
- Fixes building with Xcode 12 ([#1527](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1527)), thanks to [Steffen Matthischke](https://github.com/HeEAaD).

# 1.18.0
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


# 1.17.3
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.2...1.17.3)

__New Features__
- tvOS push support ([#1375](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1375)), thanks to [Thomas Kollbach](https://github.com/toto).

__Fixes__
- Update xcbuildtools submodule ([#1365](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1365)), thanks to [Darren Black](https://github.com/drdaz).
- Bandaid for Crashlytics [#944](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/944) ([#1376](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1376)), thanks to [Rogers George](https://github.com/ceramicatheist).
- Fix Class properties ([#1400](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1400)), thanks to [Thomas Kollbach](https://github.com/toto).
- Upgrade ParseFacebookUtils dependency to Facebook SDK v5.x ([#1424](https://github.com/parse-community/Parse-SDK-iOS-OSX/pull/1424)) thanks to [Herrick Wolber](https://github.com/rico237) and [Darren Black](https://github.com/drdaz).
