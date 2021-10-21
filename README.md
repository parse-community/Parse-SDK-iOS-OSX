![parse-repository-header-sdk-objc](https://user-images.githubusercontent.com/5673677/138286296-f4e855c3-2c8f-4c20-b637-51dd518ba0f6.png)

<h3 align="center">iOS · iPadOS · macOS · watchOS · tvOS</h3>

---

[![Build Status CI](https://github.com/parse-community/Parse-SDK-iOS-OSX/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Aci+branch%3Amaster)
[![Build Status Release](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions/workflows/release.yml/badge.svg)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Arelease)
[![Build Status Carthage](https://circleci.com/gh/parse-community/Parse-SDK-iOS-OSX.svg?style=shield)](https://circleci.com/build-insights/gh/parse-community/Parse-SDK-iOS-OSX/master)
[![Snyk Badge](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX/badge.svg)](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-iOS-OSX/master.svg)](https://codecov.io/github/parse-community/Parse-SDK-iOS-OSX?branch=master)

![Platforms](http://img.shields.io/cocoapods/p/Parse.svg?style=flat)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/carthage/carthage)

[![Pod](https://img.shields.io/cocoapods/v/Parse.svg)](https://cocoapods.org/pods/Parse)

[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![License][license-svg]][license-link]
[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Twitter](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)

---

A library that gives you access to the powerful Parse Server backend from your iOS, iPadOS, macOS, watchOS and tvOS app. For more information about the Parse Platform and its features, see the public [documentation][docs]. Check out some of the [apps using Parse](https://www.appsight.io/sdk/parse).

---

- [Getting Started](#getting-started)
  - [Other Installation Options](#other-installation-options)
    - [CocoaPods](#cocoapods)
    - [Carthage](#carthage)
    - [Compiling for yourself](#compiling-for-yourself)
    - [Using Parse as a sub-project](#using-parse-as-a-sub-project)
- [How Do I Contribute?](#how-do-i-contribute)
- [Dependencies](#dependencies)

## Getting Started

To use parse, head on over to the [releases][releases] page, and download the latest build.
And you're off!. Take a look at the public [documentation][docs] & [API][api] and start building.

Notice the API docs aren't totally up to date when it comes to latest Swift signature of the methods and more importantly regarding [Push Notifications](http://blog.parse.com/learn/engineering/the-dangerous-world-of-client-push/) which are **no longer supported by Parse server**, keep an eye on [its repo](https://github.com/ParsePlatform/parse-server)

### Other Installation Options

#### [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'Parse'
```

Run `pod install`, and you should now have the latest parse release.

If you wish to use the Facebook or Twitter utils or ParseUI,
you can now leverage Cocoapods 'subspecs'

```ruby
pod 'Parse/FacebookUtils'
pod 'Parse/TwitterUtils'
pod 'Parse/UI'
```

Note that in this case, the Parse framework will contain all headers and classes, so you just have to use:

```swift
import Parse
```

```objc
@import Parse;
```

#### [Carthage](https://github.com/carthage/carthage)

Add the following line to your Cartfile:
```
github "parse-community/Parse-SDK-iOS-OSX"
```
Run `carthage update`, and you should now have the latest version of Parse SDK in your Carthage folder.

This will also compile the ParseTwitterUtils, ParseFacebookUtilsV4 as well as ParseUI frameworks.

#### Compiling for yourself

If you want to manually compile the SDK, clone it locally, and run the following commands in the root directory of the repository:

```
# To pull in extra dependencies (Bolts and OCMock)
git submodule update --init --recursive

# To install bundler
gem install bundler

# To install all the gems via bundler
bundle install

# Build & Package the Frameworks
bundle exec rake package:frameworks
```

Compiled frameworks will be in multiple archives inside the `build/release` folder: 
- `Parse-iOS.zip`
- `Parse-macOS.zip`
- `Parse-tvOS.zip`
- `Parse-watchOS.zip`
- `ParseFacebookUtils-iOS.zip`
- `ParseFacebookUtils-tvOS.zip`
- `ParseTwitterUtils-iOS.zip`
- `ParseUI.zip`

#### Using Parse as a sub-project

You can also include parse as a subproject inside of your application if you'd prefer, although we do not recommend this, as it will increase your indexing time significantly. To do so, just drag and drop the Parse.xcodeproj file into your workspace. Note that unit tests will be unavailable if you use Parse like this, as OCMock will be unable to be found.

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

## Dependencies

We use the following libraries as dependencies inside of Parse:

 - [Bolts][bolts-framework], for task management.
 - [OCMock][ocmock-framework], for unit testing.

[docs]: http://docs.parseplatform.org/ios/guide/
[api]: http://parseplatform.org/Parse-SDK-iOS-OSX/api/
[parseui-link]: https://github.com/parse-community/ParseUI-iOS
[releases]: https://github.com/parse-community/Parse-SDK-iOS-OSX/releases
[contributing]: https://github.com/parse-community/Parse-SDK-iOS-OSX/blob/master/CONTRIBUTING.md
[bolts-framework]: https://github.com/BoltsFramework/Bolts-ObjC
[ocmock-framework]: http://ocmock.org
[license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
[license-link]: LICENSE
[open-collective-link]: https://opencollective.com/parse-server
