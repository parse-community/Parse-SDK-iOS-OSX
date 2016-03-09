/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFQuery.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFQuery` class that are synchronous, but have asynchronous counterpart,
 Calling one of these synchronous methods could potentially block the current thread for a large amount of time,
 since it might be fetching from network or saving/loading data from disk.
 */
@interface PFQuery<PFGenericObject : PFObject *> (Synchronous)

///--------------------------------------
#pragma mark - Getting Objects by ID
///--------------------------------------

/**
 Returns a `PFObject` with a given class and id.

 @param objectClass The class name for the object that is being requested.
 @param objectId The id of the object that is being requested.

 @return The `PFObject` if found. Returns `nil` if the object isn't found, or if there was an error.
 */
+ (nullable PFGenericObject)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId PF_SWIFT_UNAVAILABLE;

/**
 Returns a `PFObject` with a given class and id and sets an error if necessary.

 @param objectClass The class name for the object that is being requested.
 @param objectId The id of the object that is being requested.
 @param error Pointer to an `NSError` that will be set if necessary.

 @return The `PFObject` if found. Returns `nil` if the object isn't found, or if there was an `error`.
 */
+ (nullable PFGenericObject)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId error:(NSError **)error;

/**
 Returns a `PFObject` with the given id.

 @warning This method mutates the query.
 It will reset limit to `1`, skip to `0` and remove all conditions, leaving only `objectId`.

 @param objectId The id of the object that is being requested.

 @return The `PFObject` if found. Returns nil if the object isn't found, or if there was an error.
 */
- (nullable PFGenericObject)getObjectWithId:(NSString *)objectId PF_SWIFT_UNAVAILABLE;

/**
 Returns a `PFObject` with the given id and sets an error if necessary.

 @warning This method mutates the query.
 It will reset limit to `1`, skip to `0` and remove all conditions, leaving only `objectId`.

 @param objectId The id of the object that is being requested.
 @param error Pointer to an `NSError` that will be set if necessary.

 @return The `PFObject` if found. Returns nil if the object isn't found, or if there was an error.
 */
- (nullable PFGenericObject)getObjectWithId:(NSString *)objectId error:(NSError **)error;

///--------------------------------------
#pragma mark - Getting User Objects
///--------------------------------------

/**
 Returns a `PFUser` with a given id.

 @param objectId The id of the object that is being requested.

 @return The PFUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (nullable PFUser *)getUserObjectWithId:(NSString *)objectId PF_SWIFT_UNAVAILABLE;

/**
 Returns a PFUser with a given class and id and sets an error if necessary.
 @param objectId The id of the object that is being requested.
 @param error Pointer to an NSError that will be set if necessary.
 @result The PFUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (nullable PFUser *)getUserObjectWithId:(NSString *)objectId error:(NSError **)error;

///--------------------------------------
#pragma mark - Getting all Matches for a Query
///--------------------------------------

/**
 Finds objects *synchronously* based on the constructed query.

 @return Returns an array of `PFObject` objects that were found.
 */
- (nullable NSArray<PFGenericObject> *)findObjects PF_SWIFT_UNAVAILABLE;

/**
 Finds objects *synchronously* based on the constructed query and sets an error if there was one.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns an array of `PFObject` objects that were found.
 */
- (nullable NSArray<PFGenericObject> *)findObjects:(NSError **)error;

///--------------------------------------
#pragma mark - Getting the First Match in a Query
///--------------------------------------

/**
 Gets an object *synchronously* based on the constructed query.

 @warning This method mutates the query. It will reset the limit to `1`.

 @return Returns a `PFObject`, or `nil` if none was found.
 */
- (nullable PFGenericObject)getFirstObject PF_SWIFT_UNAVAILABLE;

/**
 Gets an object *synchronously* based on the constructed query and sets an error if any occurred.

 @warning This method mutates the query. It will reset the limit to `1`.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns a `PFObject`, or `nil` if none was found.
 */
- (nullable PFGenericObject)getFirstObject:(NSError **)error;

///--------------------------------------
#pragma mark - Counting the Matches in a Query
///--------------------------------------

/**
 Counts objects *synchronously* based on the constructed query.

 @return Returns the number of `PFObject` objects that match the query, or `-1` if there is an error.
 */
- (NSInteger)countObjects PF_SWIFT_UNAVAILABLE;

/**
 Counts objects *synchronously* based on the constructed query and sets an error if there was one.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns the number of `PFObject` objects that match the query, or `-1` if there is an error.
 */
- (NSInteger)countObjects:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
