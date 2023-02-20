![parse-repository-header-sdk-apple](https://user-images.githubusercontent.com/5673677/198421762-993c89e8-8201-40f1-a650-c2e9dde4da82.png)

<h3 align="center">iOS · iPadOS · macOS · watchOS · tvOS</h3>

---

[![Build Status CI](https://github.com/parse-community/Parse-SDK-iOS-OSX/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Aci+branch%3Amaster)
[![Build Status Release](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions/workflows/release-automated.yml/badge.svg)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Arelease-automated)
[![Snyk Badge](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX/badge.svg)](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-iOS-OSX/master.svg)](https://codecov.io/github/parse-community/Parse-SDK-iOS-OSX?branch=master)
[![auto-release](https://img.shields.io/badge/%F0%9F%9A%80-auto--release-9e34eb.svg)](https://github.com/parse-community/Parse-SDK-iOS-OSX/releases)

![SPM](https://img.shields.io/badge/Swift_Package_Manager-compatible-green?style=flat)

[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![License][license-svg]][license-link]
[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Twitter](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)

---

A library that gives you access to the powerful Parse Server backend from your iOS, iPadOS, macOS, watchOS and tvOS app. For more information about the Parse Platform and its features, see the public [documentation][docs]. Check out some of the [apps using Parse](https://www.appsight.io/sdk/parse).

---

- [Getting Started](#getting-started)
  - [Alternative Installation Options](#alternative-installation-options)
    - [Download Builds](#download-builds)
    - [Compile Source](#compile-source)
    - [Add Sub-Project](#add-sub-project)
- [How Do I Contribute?](#how-do-i-contribute)
- [Dependencies](#dependencies)

## Getting Started

The easiest way to install the SDK is via Swift Package Manager.

1. Open Xcode > File > Add packages...
2. Add the following package URL:
  ```
  https://github.com/parse-community/Parse-SDK-iOS-OSX
  ```
3. Add package
3. Choose the submodules you want to install

Take a look at the public [documentation][docs] & [API][api] and start building.

### Alternative Installation Options

#### Download Builds

Download the compiled builds from the asset section in the [releases][releases] page.

#### Compile Source

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

#### Add Sub-Project

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
