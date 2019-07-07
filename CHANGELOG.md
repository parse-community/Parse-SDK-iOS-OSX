# Parse-SDK-iOS-OSX Changelog

### master
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.3...master)

### 1.17.3
[Full Changelog](https://github.com/parse-community/Parse-SDK-iOS-OSX/compare/1.17.2...1.17.3)

- FIX: [#1411](https://github.com/parse-community/Parse-SDK-iOS-OSX/issues/1411) Upgrade ParseFacebookUtils dependency to Facebook SDK v5.2.1 
- Bump version to 1.17.3

### 1.17.0-alpha.6

- Fix: NSInternalInconsistencyException handling starting Bolts 1.9.0 by emitting soft NSErrors
- Fix: issue affecting public getter/setters in PFACL's in Swift (#1083)
- Prevent deadlocks when saving objects with circular references (#916)
- Prevent deadlocks when running fetchAll with circular references (#1184)
- Adds NSNotification when an invalid session token is encountered
