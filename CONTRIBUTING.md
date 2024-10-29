# Contributing to the Parse Apple SDK <!-- omit in toc -->

- [Contributing](#contributing)
- [Bugs](#bugs)
  - [Known Issues](#known-issues)
  - [Reporting Issues](#reporting-issues)
  - [Security Bugs](#security-bugs)
- [Code of Conduct](#code-of-conduct)
 
# Contributing

For analyzing bugs, creating bug fixes and features we recommend to clone this repository locally and add it as a local package to your Xcode project. This way you can edit and inspect the Parse SDK while running your app. You can find step-by-step instructions for how do that in the [Xcode docs](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package).

1. Fork the repository and create a new branch.
2. Add unit tests for any new code you add:
   - Core Module - [/Parse/Tests/Unit/](/Parse/Tests/Unit/)
3. If you've changed APIs, update the documentation and the [iOS Guide](https://github.com/parse-community/docs/tree/gh-pages/_includes/ios).
4. Ensure the test suite passes.
   You can run the tests in the command line with rake.

   Install all dependencies:
   ```
   git submodule update --init --recursive
   gem install bundler -v 2.5.22
   bundle install
   ```
   Run the tests:
   ```
   bundle exec rake test:ios
   ```
5. Ensure the project builds. You can use the [Starter Projects](https://github.com/parse-community/Parse-SDK-iOS-OSX/tree/master/ParseStarterProject) to perform integration tests.
   ```
   bundle exec rake build:starters
   ```
   Check the [Rakefile](Rakefile) and the [GitHub workflows](.github/workflows) for more information.

# Bugs

Although we try to keep developing with the Parse Platform easy, you still may run into some issues. General questions should be asked in our [community forum](community-forum), technical questions should be asked on [Stack Overflow][stack-overflow], and for everything else we use GitHub issues.

## Known Issues

We use GitHub issues to track public bugs. We keep a close eye on this and try to make it clear when a fix is in progress. Before filing a new issue, check existing issues for the same problem.

## Reporting Issues

Not all issues are SDK issues. If you're unsure whether your bug is with the SDK or backend, you can test to see if it reproduces with our [REST API][rest-api] and Parse Dashboard API Console. If it does, you can [report bugs on the Parse Server repository](https://github.com/parse-community/parse-server/issues/new/choose).

To view the REST API network requests issued by the Parse SDK, please check out our [Network Debugging Tool][network-debugging-tool].

Details are key. The more information you provide us the easier it'll be for us to debug and the faster you'll receive a fix. Some examples of useful tidbits:

* A description. What did you expect to happen and what actually happened? Why do you think that was wrong?
* A simple unit test that fails. Refer [here][tests-dir] for examples of existing unit tests. See our [README](README.md#usage) for how to run unit tests. You can submit a pull request with your failing unit test so that our CI verifies that the test fails.
* What version does this reproduce on? What version did it last work on?
* [Stacktrace or GTFO][stacktrace-or-gtfo]. In all honesty, full stacktraces with line numbers make a happy developer.
* Anything else you find relevant.


## Security Bugs

Please follow our [security documentation](https://github.com/parse-community/.github/blob/master/SECURITY.md) for the safe disclosure of security bugs. In those cases, please go through the process outlined on that page and do not file a public issue.

# Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](https://github.com/parse-community/.github/blob/master/CODE_OF_CONDUCT.md). By participating, you are expected to honor this code.

 [stack-overflow]: http://stackoverflow.com/tags/parse-platform
 [rest-api]: https://docs.parseplatform.org/rest/guide/
 [network-debugging-tool]: https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/wiki/Network-Debug-Tool
 [stacktrace-or-gtfo]: http://i.imgur.com/jacoj.jpg
 [community-forum]: https://community.parseplatform.org
