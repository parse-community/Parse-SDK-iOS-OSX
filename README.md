# Parse SDK for iOS/OS X/watchOS/tvOS

![Platforms][platforms-svg]
[![License][license-svg]][license-link]

[![Podspec][podspec-svg]][podspec-link]
[![Carthage compatible][carthage-svg]](carthage-link)
[![Dependencies][dependencies-svg]][dependencies-link]
[![References][references-svg]][references-link]

[![Build Status][build-status-svg]][build-status-link]
[![Coverage Status][coverage-status-svg]][coverage-status-link]

[![Join Chat][gitter-svg]][gitter-link]

A library that gives you access to the powerful Parse cloud platform from your iOS or OS X app.
For more information Parse and its features, see [the website][parse.com] and [getting started][docs].

## Getting Started

To use parse, head on over to the [releases][releases] page, and download the latest build.
And you're off! Take a look at the public [documentation][docs] and start building.

**Other Installation Options**

 - **[CocoaPods](https://cocoapods.org)**
 
   Add the following line to your Podfile:
   ```ruby
   pod 'Parse'
   ```
   Run `pod install`, and you should now have the latest parse release.
    
    
 - **[Carthage](https://github.com/carthage/carthage)**
 
   Add the following line to your Cartfile:
   ```
   github "ParsePlatform/Parse-SDK-iOS-OSX"
   ```
   Run `carthage update`, and you should now have the latest version of Parse SDK in your Carthage folder.

 - **Compiling for yourself**

    If you want to manually compile the SDK, clone it locally, and run the following commands in the root directory of the repository:

        # To pull in extra dependencies (Bolts and OCMock)
        git submodule update --init --recursive

        # To install all the gems
        bundle install

        # Build & Package the Frameworks
        rake package:frameworks

    Compiled frameworks will be in 2 archives: `Parse-iOS.zip` and `Parse-OSX.zip` inside the `build/release` folder, and you can link them as you'd please.

 - **Using Parse as a sub-project**

    You can also include parse as a subproject inside of your application if you'd prefer, although we do not recommend this, as it will increase your indexing time significantly. To do so, just drag and drop the Parse.xcodeproj file into your workspace. Note that unit tests will be unavailable if you use Parse like this, as OCMock will be unable to be found.

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

## Dependencies

We use the following libraries as dependencies inside of Parse:

 - [Bolts][bolts-framework], for task management.
 - [OCMock][ocmock-framework], for unit testing.

## Other Parse Projects

 - [ParseUI for iOS][parseui-link]
 - [ParseFacebookUtils for iOS][parsefacebookutils-link]
 - [ParseTwitterUtils for iOS][parsetwitterutils-link]

## License

```
Copyright (c) 2015-present, Parse, LLC.
All rights reserved.

This source code is licensed under the BSD-style license found in the
LICENSE file in the root directory of this source tree. An additional grant
of patent rights can be found in the PATENTS file in the same directory.
```

 [parse.com]: https://www.parse.com/products/ios
 [docs]: https://www.parse.com/docs/ios/guide
 [blog]: https://blog.parse.com/

 [parseui-link]: https://github.com/ParsePlatform/ParseUI-iOS
 [parsefacebookutils-link]: https://github.com/ParsePlatform/ParseFacebookUtils-iOS
 [parsetwitterutils-link]: https://github.com/ParsePlatform/ParseTwitterUtils-iOS

 [releases]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/releases
 [contributing]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/CONTRIBUTING.md

 [bolts-framework]: https://github.com/BoltsFramework/Bolts-ObjC
 [ocmock-framework]: http://ocmock.org

 [build-status-svg]: https://img.shields.io/travis/ParsePlatform/Parse-SDK-iOS-OSX/master.svg
 [build-status-link]: https://travis-ci.org/ParsePlatform/Parse-SDK-iOS-OSX/branches

 [coverage-status-svg]: https://img.shields.io/codecov/c/github/ParsePlatform/Parse-SDK-iOS-OSX/master.svg
 [coverage-status-link]: https://codecov.io/github/ParsePlatform/Parse-SDK-iOS-OSX?branch=master

 [license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
 [license-link]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/LICENSE

 [podspec-svg]: https://img.shields.io/cocoapods/v/Parse.svg
 [podspec-link]: https://cocoapods.org/pods/Parse
 
 [carthage-svg]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
 [carthage-link]: https://github.com/carthage/carthage

 [platforms-svg]: http://img.shields.io/cocoapods/p/Parse.svg?style=flat

 [dependencies-svg]: https://img.shields.io/badge/dependencies-2-yellowgreen.svg
 [dependencies-link]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/Vendor

 [references-svg]: https://www.versioneye.com/objective-c/parse/reference_badge.svg
 [references-link]: https://www.versioneye.com/objective-c/parse/references

 [gitter-svg]: https://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg
 [gitter-link]: https://gitter.im/ParsePlatform/Chat
