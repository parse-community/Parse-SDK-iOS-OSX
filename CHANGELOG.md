# Parse-SDK-iOS-OSX Chnagelog

### master

* Fixes NSInternalInconsistencyException handling starting Bolts 1.9.0 by emitting soft NSErrors
* Fixes issue affecting public getter/setters in PFACL's in Swift (#1083)
* Prevent deadlocks when saving objects with cicrular references (#916)
* Prevent deadlocks when running fetchAll with circluar references (#1184)
* Adds NSNotification when an invalid session token is encountered

