# Parse SDK for iOS/OS X

[![Build Status][build-status-svg]][build-status-link]
[![Coverage Status][coverage-status-svg]][coverage-status-link]
[![Podspec][podspec-svg]][podspec-link]
[![License][license-svg]][license-link]
![Platforms][platforms-svg]
[![Dependencies][dependencies-svg]][dependencies-link]
[![References][references-svg]][references-link]

A library that gives you access to the powerful Parse cloud platform from your iOS or OS X app.
For more information Parse and its features, see [the website][parse.com] and [getting started][docs].

## Other Parse Projects

 - [ParseUI for iOS][parseui-ios-link]
 - [Parse SDK for Android][android-sdk-link]

## Getting Started

To use parse, head on over to the [releases][releases] page, and download the latest build.
And you're off! Take a look at the public [documentation][docs] and start building.

**Other Installation Options**

 1. **CocoaPods**

    Add the following line to your podfile:

        pod 'Parse'

    Run pod install, and you should now have the latest parse release.

 2. **Compiling for yourself**

    If you want to manually compile the SDK, clone it locally, and run the following command in the root directory of the repository:

        rake package:frameworks

    Compiled frameworks will be in 2 archives: `Parse-iOS.zip` and `Parse-OSX.zip` inside the `build/release` folder, and you can link them as you'd please.

 3. **Using Parse as a sub-project**

    You can also include parse as a subproject inside of your application if you'd prefer, although we do not recommend this, as it will increase your indexing time significantly. To do so, just drag and drop the Parse.xcodeproj file into your workspace. Note that unit tests will be unavailable if you use Parse like this, as OCMock will be unable to be found.

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

## Dependencies

We use the following libraries as dependencies inside of Parse:

 - [Bolts][bolts-framework], for task management.
 - [OCMock][ocmock-framework], for unit testing.

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

 [parseui-ios-link]: https://github.com/ParsePlatform/ParseUI-iOS
 [android-sdk-link]: https://github.com/ParsePlatform/Parse-SDK-Android
 
 [releases]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/releases
 [contributing]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/CONTRIBUTING.md

 [bolts-framework]: https://github.com/BoltsFramework/Bolts-iOS 
 [ocmock-framework]: http://ocmock.org

 [build-status-svg]: https://travis-ci.org/ParsePlatform/Parse-SDK-iOS-OSX.svg
 [build-status-link]: https://travis-ci.org/ParsePlatform/Parse-SDK-iOS-OSX/branches

 [coverage-status-svg]: https://coveralls.io/repos/ParsePlatform/Parse-SDK-iOS-OSX/badge.svg?branch=master&service=github
 [coverage-status-link]: https://coveralls.io/github/ParsePlatform/Parse-SDK-iOS-OSX?branch=master

 [license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
 [license-link]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/LICENSE

 [podspec-svg]: https://img.shields.io/cocoapods/v/Parse.svg
 [podspec-link]: https://cocoapods.org/pods/Parse

 [platforms-svg]: https://img.shields.io/badge/platform-ios%20%7C%20osx-lightgrey.svg

 [dependencies-svg]: https://img.shields.io/badge/dependencies-2-yellowgreen.svg
 [dependencies-link]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/master/Vendor

 [references-svg]: https://www.versioneye.com/objective-c/parse/reference_badge.svg
 [references-link]: https://www.versioneye.com/objective-c/parse/references
