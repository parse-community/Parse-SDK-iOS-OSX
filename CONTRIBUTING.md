# Contributing to the Parse SDK for iOS/OS X
We want to make contributing to this project as easy and transparent as possible.

## Our Development Process

### `master` is unsafe
Our goal is to keep `master` stable, but there may be changes that your application may not be compatible with. We'll do our best to publicize any breaking changes, but try to use specific releases in any production environment.

### Pull Requests
We actively welcome your pull requests. When we get one, we'll run some Parse-specific integration tests on it first. From here, we'll need to get a core member to sign off on the changes and then merge the pull request.

#### 1. Fork the repo and create your branch from `master`.

#### 2. Add unit tests for any new code you add.
- Main SDK - [/Parse/Tests/Unit/](/Parse/Tests/Unit/)
- Facebook Utils - [/ParseFacebookUtils/Tests/Unit/](/ParseFacebookUtils/Tests/Unit/)
- Twitter Utils - [/ParseTwitterUtils/Tests/Unit/](/ParseTwitterUtils/Tests/Unit/)

#### 3. If you've changed APIs, update the documentation and the [iOS Guide](https://github.com/parse-community/docs/tree/gh-pages/_includes/ios)

#### 4. Ensure the test suite passes.
You can run the tests in the command line with rake.

Install all dependencies:
```
git submodule update --init --recursive
gem install bundler
bundle install
```
Run the tests:
```
bundle exec rake test:ios
```
Check the Rakefile and the circleci config for more information.
   
#### 5. Make sure your code follows the [style guide](#style-guide)

### Preparing for a new release

#### Update the version number

You can use the rake task in order to bump the version number, it's safe, and will properly update all version numbers

```
$ bundle exec rake package:set_version[X.X.X]
```

Note that zsh users (such as those using macOS >= 10.15) need to escape the brackets as follows:

```
$ bundle exec rake package:set_version\[X.X.X\]
```

Replace X.X.X by the version number and push to the repository.

## Bugs
Although we try to keep developing with the Parse Platform easy, you still may run into some issues. General questions should be asked on our [community forum](community-forum), technical questions should be asked on [Stack Overflow][stack-overflow], and for everything else we use GitHub issues.

### Known Issues
We use GitHub issues to track public bugs. We keep a close eye on this and try to make it clear when a fix is in progress. Before filing a new issue, check existing issues for the same problem.

### Reporting New Issues
Not all issues are SDK issues. If you're unsure whether your bug is with the SDK or backend, you can test to see if it reproduces with our [REST API][rest-api] and Parse Dashboard API Console. If it does, you can [report bugs on the Parse Server repository](https://github.com/parse-community/parse-server/issues/new/choose).

To view the REST API network requests issued by the Parse SDK, please check out our [Network Debugging Tool][network-debugging-tool].

Details are key. The more information you provide us the easier it'll be for us to debug and the faster you'll receive a fix. Some examples of useful tidbits:

* A description. What did you expect to happen and what actually happened? Why do you think that was wrong?
* A simple unit test that fails. Refer [here][tests-dir] for examples of existing unit tests. See our [README](README.md#usage) for how to run unit tests. You can submit a pull request with your failing unit test so that our CI verifies that the test fails.
* What version does this reproduce on? What version did it last work on?
* [Stacktrace or GTFO][stacktrace-or-gtfo]. In all honesty, full stacktraces with line numbers make a happy developer.
* Anything else you find relevant.


### Security Bugs
Please follow our [security documentation](https://github.com/parse-community/.github/blob/master/SECURITY.md) for the safe disclosure of security bugs. In those cases, please go through the process outlined on that page and do not file a public issue.

## Style Guide
We're still working on providing a code style for your IDE and getting a linter on GitHub, but for now try to keep the following:

* Most importantly, match the existing code style as much as possible.
* Try to keep lines under 120 characters, if possible.

## License
By contributing to Parse iOS/OSX SDK, you agree that your contributions will be licensed under its license.

# Code of Conduct
This project adheres to the [Contributor Covenant Code of Conduct](https://github.com/parse-community/.github/blob/master/CODE_OF_CONDUCT.md). By participating, you are expected to honor this code.

 [stack-overflow]: http://stackoverflow.com/tags/parse-platform
 [rest-api]: https://docs.parseplatform.org/rest/guide/
 [network-debugging-tool]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/wiki/Network-Debug-Tool
 [stacktrace-or-gtfo]: http://i.imgur.com/jacoj.jpg
 [community-forum]: https://community.parseplatform.org
