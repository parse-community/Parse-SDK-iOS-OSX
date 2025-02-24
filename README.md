![parse-repository-header-sdk-apple](https://user-images.githubusercontent.com/5673677/198421762-993c89e8-8201-40f1-a650-c2e9dde4da82.png)

<h3 align="center">iOS · iPadOS · macOS · watchOS · tvOS · visionOS</h3>

---

[![Build Status CI](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Aci+branch%3Amaster)
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
[![Chat](https://img.shields.io/badge/Chat-Join!-%23fff?style=social&logo=slack)](https://chat.parseplatform.org)

---

A library that gives you access to the powerful Parse Server backend from your iOS, iPadOS, macOS, watchOS, tvOS, and visionOS app. For more information about the Parse Platform and its features, see the public [documentation][docs].

---

- [Getting Started](#getting-started)
- [Compatibility](#compatibility)
  - [Parse Server](#parse-server)
  - [Xcode, iOS, macOS, tvOS, watchOS](#xcode-ios-macos-tvos-watchos)
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
4. Choose the submodules you want to install

Take a look at the public [documentation][docs] & [API][api] and start building.

## Compatibility

### Parse Server

Parse Apple SDK is compatible with the following versions of Parse Server.

| Parse Apple SDK | Parse Server |
|-----------------|--------------|
| 1.0.0           | >= 1.0.0     |

### Xcode, iOS, macOS, tvOS, watchOS

The Parse Apple SDK is continuously tested with the most recent releases of Xcode to ensure compatibility. We follow the annual release schedule of Xcode to support the current and previous major Xcode version.

| Xcode Version | iOS Version | macOS Version | watchOS Version | tvOS Version | Release Date   | End-of-Support Date | Parse Apple SDK Support |
|---------------|-------------|---------------|-----------------|--------------|----------------|---------------------|-------------------------|
| Xcode 13      | iOS 15      | macOS 12      | watchOS 8       | tvOS 15      | September 2021 | October 2023        | >= 1.19.3 < 2.7.2       |
| Xcode 14      | iOS 16      | macOS 13      | watchOS 9       | tvOS 16      | September 2022 | October 2024        | >= 2.7.2 < 5.0.0        |
| Xcode 15      | iOS 17      | macOS 14      | watchOS 10      | tvOS 17      | September 2023 | October 2025        | >= 3.0.0                |
| Xcode 16      | iOS 18      | macOS 15      | watchOS 11      | tvOS 18      | September 2024 | tbd                 | >= 4.2.0                |

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

## Dependencies

We use the following libraries as dependencies inside of Parse:

 - [Bolts][bolts-framework], for task management.
 - [OCMock][ocmock-framework], for unit testing.

[docs]: http://docs.parseplatform.org/ios/guide/
[api]: http://parseplatform.org/Parse-SDK-iOS-OSX/api/
[contributing]: https://github.com/parse-community/Parse-SDK-iOS-OSX/blob/master/CONTRIBUTING.md
[bolts-framework]: https://github.com/BoltsFramework/Bolts-ObjC
[ocmock-framework]: http://ocmock.org
[license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
[license-link]: LICENSE
[open-collective-link]: https://opencollective.com/parse-server
