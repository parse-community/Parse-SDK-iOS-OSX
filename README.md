![parse-repository-header-sdk-apple](https://user-images.githubusercontent.com/5673677/198421762-993c89e8-8201-40f1-a650-c2e9dde4da82.png)

<h3 align="center">iOS · iPadOS · macOS · watchOS · tvOS</h3>

---

[![Build Status CI](https://github.com/parse-community/Parse-SDK-iOS-OSX/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Aci+branch%3Amaster)
[![Build Status Release](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions/workflows/release-automated.yml/badge.svg)](https://github.com/parse-community/Parse-SDK-iOS-OSX/actions?query=workflow%3Arelease-automated)
[![Snyk Badge](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX/badge.svg)](https://snyk.io/test/github/parse-community/Parse-SDK-iOS-OSX)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-iOS-OSX/master.svg)](https://codecov.io/github/parse-community/Parse-SDK-iOS-OSX?branch=master)
[![auto-release](https://img.shields.io/badge/%F0%9F%9A%80-auto--release-9e34eb.svg)](https://github.com/parse-community/Parse-SDK-iOS-OSX/releases)

![iOS](https://img.shields.io/badge/iOS-12.0-green?style=flat)
![iPad](https://img.shields.io/badge/ipadOS-12.0-green?style=flat)
![macOS](https://img.shields.io/badge/macOS-10.15-green?style=flat)
![watchOS](https://img.shields.io/badge/watchOS-2.0-green?style=flat)
![tvOS](https://img.shields.io/badge/tvOS-12.0-green?style=flat)

![SPM](https://img.shields.io/badge/Swift_Package_Manager-compatible-green?style=flat)

[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![License][license-svg]][license-link]
[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Twitter](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)
[![Chat](https://img.shields.io/badge/Chat-Join!-%23fff?style=social&logo=slack)](https://chat.parseplatform.org)

---

A library that gives you access to the powerful Parse Server backend from your iOS, iPadOS, macOS, watchOS and tvOS app. For more information about the Parse Platform and its features, see the public [documentation][docs].

---

- [Getting Started](#getting-started)
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
