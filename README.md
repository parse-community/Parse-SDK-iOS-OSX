<p align="center">
    <img alt="Parse Platform" src="Assets/logo large.png" width="200">
  </a>
</p>

<h2 align="center">Parse SDK for iOS | macOS | watchOS | tvOS</h2>

<p align="center">
    A library that gives you access to the powerful Parse Server backend from your iOS or macOS app.
</p>

<p align="center">
    <a href="https://twitter.com/intent/follow?screen_name=parseplatform"><img alt="Follow on Twitter" src="https://img.shields.io/twitter/follow/parseplatform?style=social&label=Follow"></a>
    <a href="https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1356"><img alt="Maintenance help wanted" src="https://img.shields.io/badge/maintenance-help%20wanted-red.svg"></a>
    <img alt="Platforms" src="http://img.shields.io/cocoapods/p/Parse.svg?style=flat">
    <a href=" https://github.com/parse-community/Parse-SDK-iOS-OSX/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-BSD-lightgrey.svg"></a>
    <a href="https://cocoapods.org/pods/Parse"><img alt="Podspec" src="https://img.shields.io/cocoapods/v/Parse.svg"></a>
    <a href="#backers"><img alt="Backers on Open Collective" src="https://opencollective.com/parse-server/backers/badge.svg" /></a>
  <a href="#sponsors"><img alt="Sponsors on Open Collective" src="https://opencollective.com/parse-server/sponsors/badge.svg" /></a>
</p>

<p align="center">
    <a href="https://github.com/carthage/carthage"><img alt="Carthage compatible" src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
    <a href="https://github.com/parse-community/Parse-SDK-iOS-OSX/blob/master/Vendor"><img alt="Dependencies" src="https://img.shields.io/badge/dependencies-2-yellowgreen.svg"></a>
    <a href="https://www.versioneye.com/objective-c/parse/references"><img alt="References" src="https://www.versioneye.com/objective-c/parse/reference_badge.svg"></a>
    <a href="https://travis-ci.org/parse-community/Parse-SDK-iOS-OSX/branches"><img alt="Build status" src="https://img.shields.io/travis/parse-community/Parse-SDK-iOS-OSX/master.svg"></a>
    <a href="https://circleci.com/build-insights/gh/parse-community/Parse-SDK-iOS-OSX/master"><img alt="Build status" src="https://circleci.com/gh/parse-community/Parse-SDK-iOS-OSX.svg?style=shield"></a>
    <a href="https://codecov.io/github/parse-community/Parse-SDK-iOS-OSX?branch=master"><img alt="Coverage status" src="https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-iOS-OSX/master.svg"></a>
    <a href="https://community.parseplatform.org/"><img alt="Join the conversation" src="https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg"></a>
</p>
<br>

For more information about the Parse Platform and its features, see the public [documentation][docs].

Check out some of the [apps using Parse](https://www.appsight.io/sdk/parse).

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

## Preparing for a new release

### Update the version number

You can use the rake task in order to bump the version number, it's safe, and will properly update all version numbers

```
$ bundle exec rake package:set_version[X.X.X]
```

Note that zsh users (such as those using macOS >= 10.15) need to escape the brackets as follows:

```
$ bundle exec rake package:set_version\[X.X.X\]
```

Replace X.X.X by the version number and push to the repository.

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

As of April 5, 2017, Parse, LLC has transferred this code to the parse-community organization, and will no longer be contributing to or distributing this code.

 [docs]: http://docs.parseplatform.org/ios/guide/
 [api]: http://parseplatform.org/Parse-SDK-iOS-OSX/api/

 [parseui-link]: https://github.com/parse-community/ParseUI-iOS

 [releases]: https://github.com/parse-community/Parse-SDK-iOS-OSX/releases
 [contributing]: https://github.com/parse-community/Parse-SDK-iOS-OSX/blob/master/CONTRIBUTING.md

 [bolts-framework]: https://github.com/BoltsFramework/Bolts-ObjC
 [ocmock-framework]: http://ocmock.org
 
 [open-collective-link]: https://opencollective.com/parse-server
 
