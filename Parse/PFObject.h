/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>

#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PFSubclassing;
@class PFRelation;
@class PFACL;

/**
 The name of the default pin that for PFObject local data store.
 */
extern NSString *const PFObjectDefaultPin;

/**
 The `PFObject` class is a local representation of data persisted to the Parse cloud.
 This is the main class that is used to interact with objects in your app.
 */
NS_REQUIRES_PROPERTY_DEFINITIONS
@interface PFObject : NSObject

///--------------------------------------
#pragma mark - Creating a PFObject
///--------------------------------------

/**
 Initializes a new empty `PFObject` instance with a class name.

 @param newClassName A class name can be any alphanumeric string that begins with a letter.
 It represents an object in your app, like a 'User' or a 'Document'.

 @return Returns the object that is instantiated with the given class name.
 */
- (instancetype)initWithClassName:(NSString *)newClassName;

/**
 Creates a new PFObject with a class name.

 @param className A class name can be any alphanumeric string that begins with a letter.
 It represents an object in your app, like a 'User' or a 'Document'.

 @return Returns the object that is instantiated with the given class name.
 */
+ (instancetype)objectWithClassName:(NSString *)className;

/**
 Creates a new `PFObject` with a class name, initialized with data
 constructed from the specified set of objects and keys.

 @param className The object's class.
 @param dictionary An `NSDictionary` of keys and objects to set on the new `PFObject`.

 @return A PFObject with the given class name and set with the given data.
 */
+ (instancetype)objectWithClassName:(NSString *)className dictionary:(nullable NSDictionary<NSString *, id> *)dictionary;

/**
 Creates a reference to an existing PFObject for use in creating associations between PFObjects.

 Calling `dataAvailable` on this object will return `NO` until `-fetchIfNeeded` has been called.
 No network request will be made.

 @param className The object's class.
 @param objectId The object id for the referenced object.

 @return A `PFObject` instance without data.
 */
+ (instancetype)objectWithoutDataWithClassName:(NSString *)className
                                      objectId:(nullable NSString *)objectId NS_SWIFT_NAME(init(withoutDataWithClassName:objectId:));

///--------------------------------------
#pragma mark - Managing Object Properties
///--------------------------------------

/**
 The class name of the object.
 */
@property (nonatomic, strong, readonly) NSString *parseClassName;

/**
 The id of the object.
 */
@property (nullable, nonatomic, strong) NSString *objectId;

/**
 When the object was last updated.
 */
@property (nullable, nonatomic, strong, readonly) NSDate *updatedAt;

/**
 When the object was created.
 */
@property (nullable, nonatomic, strong, readonly) NSDate *createdAt;

/**
 The ACL for this object.
 */
@property (nullable, nonatomic, strong) PFACL *ACL;

/**
 Returns an array of the keys contained in this object.

 This does not include `createdAt`, `updatedAt`, `authData`, or `objectId`.
 It does include things like username and ACL.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *allKeys;

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

/**
 Returns the value associated with a given key.

 @param key The key for which to return the corresponding value.

 @see -objectForKeyedSubscript:
 */
- (nullable id)objectForKey:(NSString *)key;

/**
 Sets the object associated with a given key.

 @param object The object for `key`. A strong reference to the object is maintained by PFObject.
 Raises an `NSInvalidArgumentException` if `object` is `nil`.
 If you need to represent a `nil` value - use `NSNull`.
 @param key The key for `object`.
 Raises an `NSInvalidArgumentException` if `key` is `nil`.

 @see -setObject:forKeyedSubscript:
 */
- (void)setObject:(id)object forKey:(NSString *)key;

/**
 Unsets a key on the object.

 @param key The key.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 Returns the value associated with a given key.

 This method enables usage of literal syntax on `PFObject`.
 E.g. `NSString *value = object[@"key"];`

 @param key The key for which to return the corresponding value.

 @see -objectForKey:
 */
- (nullable id)objectForKeyedSubscript:(NSString *)key;

/**
 Returns the value associated with a given key.

 This method enables usage of literal syntax on `PFObject`.
 E.g. `object[@"key"] = @"value";`

 @param object The object for `key`. A strong reference to the object is maintained by PFObject.
 Raises an `NSInvalidArgumentException` if `object` is `nil`.
 If you need to represent a `nil` value - use `NSNull`.
 @param key The key for `object`.
 Raises an `NSInvalidArgumentException` if `key` is `nil`.

 @see -setObject:forKey:
 */
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;

/**
 Returns the instance of `PFRelation` class associated with the given key.

 @param key The key that the relation is associated with.
 */
- (PFRelation *)relationForKey:(NSString *)key;

/**
 Returns the instance of `PFRelation` class associated with the given key.

 @param key The key that the relation is associated with.

 @deprecated Please use `PFObject.-relationForKey:` instead.
 */
- (PFRelation *)relationforKey:(NSString *)key PARSE_DEPRECATED("Please use -relationForKey: instead.");

/**
 Clears any changes to this object made since the last call to save and sets it back to the server state.
 */
- (void)revert;

/**
 Clears any changes to this object's key that were done after last successful save and sets it back to the
 server state.

 @param key The key to revert changes for.
 */
- (void)revertObjectForKey:(NSString *)key;

///--------------------------------------
#pragma mark - Array Accessors
///--------------------------------------

/**
 Adds an object to the end of the array associated with a given key.

 @param object The object to add.
 @param key The key.
 */
- (void)addObject:(id)object forKey:(NSString *)key;

/**
 Adds the objects contained in another array to the end of the array associated with a given key.

 @param objects The array of objects to add.
 @param key The key.
 */
- (void)addObjectsFromArray:(NSArray *)objects forKey:(NSString *)key;

/**
 Adds an object to the array associated with a given key, only if it is not already present in the array.

 The position of the insert is not guaranteed.

 @param object The object to add.
 @param key The key.
 */
- (void)addUniqueObject:(id)object forKey:(NSString *)key;

/**
 Adds the objects contained in another array to the array associated with a given key,
 only adding elements which are not already present in the array.

 @dicsussion The position of the insert is not guaranteed.

 @param objects The array of objects to add.
 @param key The key.
 */
- (void)addUniqueObjectsFromArray:(NSArray *)objects forKey:(NSString *)key;

/**
 Removes all occurrences of an object from the array associated with a given key.

 @param object The object to remove.
 @param key The key.
 */
- (void)removeObject:(id)object forKey:(NSString *)key;

/**
 Removes all occurrences of the objects contained in another array from the array associated with a given key.

 @param objects The array of objects to remove.
 @param key The key.
 */
- (void)removeObjectsInArray:(NSArray *)objects forKey:(NSString *)key;

///--------------------------------------
#pragma mark - Increment
///--------------------------------------

/**
 Increments the given key by `1`.

 @param key The key.
 */
- (void)incrementKey:(NSString *)key;

/**
 Increments the given key by a number.

 @param key The key.
 @param amount The amount to increment.
 */
- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount;

///--------------------------------------
#pragma mark - Saving Objects
///--------------------------------------

/**
 Saves the `PFObject` *asynchronously*.

 @return The task that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveInBackground;

/**
 Saves the `PFObject` *asynchronously* and executes the given callback block.

 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
- (void)saveInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 Saves this object to the server at some unspecified time in the future,
 even if Parse is currently inaccessible.

 Use this when you may not have a solid network connection, and don't need to know when the save completes.
 If there is some problem with the object such that it can't be saved, it will be silently discarded.

 Objects saved with this method will be stored locally in an on-disk cache until they can be delivered to Parse.
 They will be sent immediately if possible. Otherwise, they will be sent the next time a network connection is
 available. Objects saved this way will persist even after the app is closed, in which case they will be sent the
 next time the app is opened. If more than 10MB of data is waiting to be sent, subsequent calls to `-saveEventually`
 will cause old saves to be silently discarded until the connection can be re-established, and the queued objects
 can be saved.

 @return The task that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveEventually PF_TV_UNAVAILABLE PF_WATCH_UNAVAILABLE;

/**
 Saves this object to the server at some unspecified time in the future,
 even if Parse is currently inaccessible.

 Use this when you may not have a solid network connection, and don't need to know when the save completes.
 If there is some problem with the object such that it can't be saved, it will be silently discarded. If the save
 completes successfully while the object is still in memory, then callback will be called.

 Objects saved with this method will be stored locally in an on-disk cache until they can be delivered to Parse.
 They will be sent immediately if possible. Otherwise, they will be sent the next time a network connection is
 available. Objects saved this way will persist even after the app is closed, in which case they will be sent the
 next time the app is opened. If more than 10MB of data is waiting to be sent, subsequent calls to `-saveEventually:`
 will cause old saves to be silently discarded until the connection can be re-established, and the queued objects
 can be saved.

 @param callback The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
- (void)saveEventually:(nullable PFBooleanResultBlock)callback PF_TV_UNAVAILABLE PF_WATCH_UNAVAILABLE;

///--------------------------------------
#pragma mark - Saving Many Objects
///--------------------------------------

/**
 Saves a collection of objects all at once *asynchronously*.

 @param objects The array of objects to save.

 @return The task that encapsulates the work being done.
 */
+ (BFTask<NSNumber *> *)saveAllInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 Saves a collection of objects all at once `asynchronously` and executes the block when done.

 @param objects The array of objects to save.
 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)saveAllInBackground:(nullable NSArray<PFObject *> *)objects
                      block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
#pragma mark - Deleting Many Objects
///--------------------------------------

/**
 Deletes a collection of objects all at once asynchronously.
 @param objects The array of objects to delete.
 @return The task that encapsulates the work being done.
 */
+ (BFTask<NSNumber *> *)deleteAllInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 Deletes a collection of objects all at once *asynchronously* and executes the block when done.

 @param objects The array of objects to delete.
 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)deleteAllInBackground:(nullable NSArray<PFObject *> *)objects
                        block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
#pragma mark - Getting an Object
///--------------------------------------

/**
 Gets whether the `PFObject` has been fetched.

 @return `YES` if the PFObject is new or has been fetched or refreshed, otherwise `NO`.
 */
@property (nonatomic, assign, readonly, getter=isDataAvailable) BOOL dataAvailable;

#if TARGET_OS_IOS

/**
 Refreshes the PFObject with the current data from the server.

 @deprecated Please use `-fetch` instead.
 */
- (nullable instancetype)refresh PF_SWIFT_UNAVAILABLE PARSE_DEPRECATED("Please use `-fetch` instead.");

/**
 *Synchronously* refreshes the `PFObject` with the current data from the server and sets an error if it occurs.

 @param error Pointer to an `NSError` that will be set if necessary.

 @deprecated Please use `-fetch:` instead.
 */
- (nullable instancetype)refresh:(NSError **)error PARSE_DEPRECATED("Please use `-fetch:` instead.");

/**
 *Asynchronously* refreshes the `PFObject` and executes the given callback block.

 @param block The block to execute.
 The block should have the following argument signature: `^(PFObject *object, NSError *error)`

 @deprecated Please use `-fetchInBackgroundWithBlock:` instead.
 */
- (void)refreshInBackgroundWithBlock:(nullable PFObjectResultBlock)block PARSE_DEPRECATED("Please use `-fetchInBackgroundWithBlock:` instead.");

#endif

/**
 Fetches the `PFObject` *asynchronously* and sets it as a result for the task.

 @return The task that encapsulates the work being done.
 */
- (BFTask<__kindof PFObject *> *)fetchInBackground;

/**
 Fetches the `PFObject` *asynchronously* and executes the given callback block.

 @param block The block to execute.
 It should have the following argument signature: `^(PFObject *object, NSError *error)`.
 */
- (void)fetchInBackgroundWithBlock:(nullable PFObjectResultBlock)block;

/**
 Fetches the `PFObject` data *asynchronously* if `dataAvailable` is `NO`,
 then sets it as a result for the task.

 @return The task that encapsulates the work being done.
 */
- (BFTask<__kindof PFObject *> *)fetchIfNeededInBackground;

/**
 Fetches the `PFObject` data *asynchronously* if `dataAvailable` is `NO`, then calls the callback block.

 @param block The block to execute.
 It should have the following argument signature: `^(PFObject *object, NSError *error)`.
 */
- (void)fetchIfNeededInBackgroundWithBlock:(nullable PFObjectResultBlock)block;

///--------------------------------------
#pragma mark - Getting Many Objects
///--------------------------------------

/**
 Fetches all of the `PFObject` objects with the current data from the server *asynchronously*.

 @param objects The list of objects to fetch.

 @return The task that encapsulates the work being done.
 */
+ (BFTask<NSArray<__kindof PFObject *> *> *)fetchAllInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 Fetches all of the `PFObject` objects with the current data from the server *asynchronously*
 and calls the given block.

 @param objects The list of objects to fetch.
 @param block The block to execute.
 It should have the following argument signature: `^(NSArray *objects, NSError *error)`.
 */
+ (void)fetchAllInBackground:(nullable NSArray<PFObject *> *)objects
                       block:(nullable PFArrayResultBlock)block;

/**
 Fetches all of the `PFObject` objects with the current data from the server *asynchronously*.

 @param objects The list of objects to fetch.

 @return The task that encapsulates the work being done.
 */
+ (BFTask<NSArray<__kindof PFObject *> *> *)fetchAllIfNeededInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 Fetches all of the PFObjects with the current data from the server *asynchronously*
 and calls the given block.

 @param objects The list of objects to fetch.
 @param block The block to execute.
 It should have the following argument signature: `^(NSArray *objects, NSError *error)`.
 */
+ (void)fetchAllIfNeededInBackground:(nullable NSArray<PFObject *> *)objects
                               block:(nullable PFArrayResultBlock)block;

///--------------------------------------
#pragma mark - Fetching From Local Datastore
///--------------------------------------

/**
 *Asynchronously* loads data from the local datastore into this object,
 if it has not been fetched from the server already.

 @return The task that encapsulates the work being done.
 */
- (BFTask<__kindof PFObject *> *)fetchFromLocalDatastoreInBackground;

/**
 *Asynchronously* loads data from the local datastore into this object,
 if it has not been fetched from the server already.

 @param block The block to execute.
 It should have the following argument signature: `^(PFObject *object, NSError *error)`.
 */
- (void)fetchFromLocalDatastoreInBackgroundWithBlock:(nullable PFObjectResultBlock)block;

///--------------------------------------
#pragma mark - Deleting an Object
///--------------------------------------

/**
 Deletes the `PFObject` *asynchronously*.

 @return The task that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)deleteInBackground;

/**
 Deletes the `PFObject` *asynchronously* and executes the given callback block.

 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
- (void)deleteInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 Deletes this object from the server at some unspecified time in the future,
 even if Parse is currently inaccessible.

 Use this when you may not have a solid network connection,
 and don't need to know when the delete completes. If there is some problem with the object
 such that it can't be deleted, the request will be silently discarded.

 Delete instructions made with this method will be stored locally in an on-disk cache until they can be transmitted
 to Parse. They will be sent immediately if possible. Otherwise, they will be sent the next time a network connection
 is available. Delete requests will persist even after the app is closed, in which case they will be sent the
 next time the app is opened. If more than 10MB of `-saveEventually` or `-deleteEventually` commands are waiting
 to be sent, subsequent calls to `-saveEventually` or `-deleteEventually` will cause old requests to be silently discarded
 until the connection can be re-established, and the queued requests can go through.

 @return The task that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)deleteEventually PF_TV_UNAVAILABLE PF_WATCH_UNAVAILABLE;

///--------------------------------------
#pragma mark - Dirtiness
///--------------------------------------

/**
 Gets whether any key-value pair in this object (or its children)
 has been added/updated/removed and not saved yet.

 @return Returns whether this object has been altered and not saved yet.
 */
@property (nonatomic, assign, readonly, getter=isDirty) BOOL dirty;

/**
 Get whether a value associated with a key has been added/updated/removed and not saved yet.

 @param key The key to check for

 @return Returns whether this key has been altered and not saved yet.
 */
- (BOOL)isDirtyForKey:(NSString *)key;

///--------------------------------------
#pragma mark - Pinning
///--------------------------------------

/**
 *Asynchronously* stores the object and every object it points to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `-fetchFromLocalDatastore` on it.

 @return The task that encapsulates the work being done.

 @see `-unpinInBackground`
 @see `PFObjectDefaultPin`
 */
- (BFTask<NSNumber *> *)pinInBackground;

/**
 *Asynchronously* stores the object and every object it points to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `-fetchFromLocalDatastore` on it.

 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see `-unpinInBackgroundWithBlock:`
 @see `PFObjectDefaultPin`
 */
- (void)pinInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* stores the object and every object it points to in the local datastore, recursively.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `-fetchFromLocalDatastore on it.

 @param name The name of the pin.

 @return The task that encapsulates the work being done.

 @see unpinInBackgroundWithName:
 */
- (BFTask<NSNumber *> *)pinInBackgroundWithName:(NSString *)name;

/**
 *Asynchronously* stores the object and every object it points to in the local datastore, recursively.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `-fetchFromLocalDatastore` on it.

 @param name    The name of the pin.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see unpinInBackgroundWithName:block:
 */
- (void)pinInBackgroundWithName:(NSString *)name block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
#pragma mark - Pinning Many Objects
///--------------------------------------

/**
 *Asynchronously* stores the objects and every object they point to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `fetchFromLocalDatastore:` on it.

 @param objects The objects to be pinned.

 @return The task that encapsulates the work being done.

 @see unpinAllInBackground:
 @see PFObjectDefaultPin
 */
+ (BFTask<NSNumber *> *)pinAllInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 *Asynchronously* stores the objects and every object they point to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `fetchFromLocalDatastore:` on it.

 @param objects The objects to be pinned.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see unpinAllInBackground:block:
 @see PFObjectDefaultPin
 */
+ (void)pinAllInBackground:(nullable NSArray<PFObject *> *)objects block:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* stores the objects and every object they point to in the local datastore, recursively.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `fetchFromLocalDatastore:` on it.

 @param objects     The objects to be pinned.
 @param name        The name of the pin.

 @return The task that encapsulates the work being done.

 @see unpinAllInBackground:withName:
 */
+ (BFTask<NSNumber *> *)pinAllInBackground:(nullable NSArray<PFObject *> *)objects withName:(NSString *)name;

/**
 *Asynchronously* stores the objects and every object they point to in the local datastore, recursively.

 If those other objects have not been fetched from Parse, they will not be stored. However,
 if they have changed data, all the changes will be retained. To get the objects back later, you can
 use a `PFQuery` that uses `PFQuery.-fromLocalDatastore`, or you can create an unfetched pointer with
 `+objectWithoutDataWithClassName:objectId:` and then call `fetchFromLocalDatastore:` on it.

 @param objects     The objects to be pinned.
 @param name        The name of the pin.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see unpinAllInBackground:withName:block:
 */
+ (void)pinAllInBackground:(nullable NSArray<PFObject *> *)objects
                  withName:(NSString *)name
                     block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
#pragma mark - Unpinning
///--------------------------------------

/**
 *Asynchronously* removes the object and every object it points to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 @return The task that encapsulates the work being done.

 @see pinInBackground
 @see PFObjectDefaultPin
 */
- (BFTask<NSNumber *> *)unpinInBackground;

/**
 *Asynchronously* removes the object and every object it points to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see pinInBackgroundWithBlock:
 @see PFObjectDefaultPin
 */
- (void)unpinInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* removes the object and every object it points to in the local datastore, recursively.

 @param name The name of the pin.

 @return The task that encapsulates the work being done.

 @see pinInBackgroundWithName:
 */
- (BFTask<NSNumber *> *)unpinInBackgroundWithName:(NSString *)name;

/**
 *Asynchronously* removes the object and every object it points to in the local datastore, recursively.

 @param name    The name of the pin.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see pinInBackgroundWithName:block:
 */
- (void)unpinInBackgroundWithName:(NSString *)name block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
#pragma mark - Unpinning Many Objects
///--------------------------------------

/**
 *Asynchronously* removes all objects in the local datastore
 using a default pin name: `PFObjectDefaultPin`.

 @return The task that encapsulates the work being done.

 @see PFObjectDefaultPin
 */
+ (BFTask<NSNumber *> *)unpinAllObjectsInBackground;

/**
 *Asynchronously* removes all objects in the local datastore
 using a default pin name: `PFObjectDefaultPin`.

 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see PFObjectDefaultPin
 */
+ (void)unpinAllObjectsInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* removes all objects with the specified pin name.

 @param name    The name of the pin.

 @return The task that encapsulates the work being done.
 */
+ (BFTask<NSNumber *> *)unpinAllObjectsInBackgroundWithName:(NSString *)name;

/**
 *Asynchronously* removes all objects with the specified pin name.

 @param name    The name of the pin.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)unpinAllObjectsInBackgroundWithName:(NSString *)name block:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* removes the objects and every object they point to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 @param objects The objects.

 @return The task that encapsulates the work being done.

 @see pinAllInBackground:
 @see PFObjectDefaultPin
 */
+ (BFTask<NSNumber *> *)unpinAllInBackground:(nullable NSArray<PFObject *> *)objects;

/**
 *Asynchronously* removes the objects and every object they point to in the local datastore, recursively,
 using a default pin name: `PFObjectDefaultPin`.

 @param objects The objects.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see pinAllInBackground:block:
 @see PFObjectDefaultPin
 */
+ (void)unpinAllInBackground:(nullable NSArray<PFObject *> *)objects block:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* removes the objects and every object they point to in the local datastore, recursively.

 @param objects The objects.
 @param name    The name of the pin.

 @return The task that encapsulates the work being done.

 @see pinAllInBackground:withName:
 */
+ (BFTask<NSNumber *> *)unpinAllInBackground:(nullable NSArray<PFObject *> *)objects withName:(NSString *)name;

/**
 *Asynchronously* removes the objects and every object they point to in the local datastore, recursively.

 @param objects The objects.
 @param name    The name of the pin.
 @param block   The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.

 @see pinAllInBackground:withName:block:
 */
+ (void)unpinAllInBackground:(nullable NSArray<PFObject *> *)objects
                    withName:(NSString *)name
                       block:(nullable PFBooleanResultBlock)block;

@end

NS_ASSUME_NONNULL_END
