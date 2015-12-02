/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFMacros.h"

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFFileManager;
@class PFObject;
@class PFPin;
@class PFQueryState;
@class PFSQLiteDatabase;
@class PFUser;

typedef NS_OPTIONS(uint8_t, PFOfflineStoreOptions)
{
    PFOfflineStoreOptionAlwaysFetchFromSQLite = 1 << 0,
};

//TODO: (nlutsenko) Bring this header up to standard with @name, method comments, etc...
@interface PFOfflineStore : NSObject

@property (nonatomic, assign, readonly) PFOfflineStoreOptions options;
@property (nonatomic, strong, readonly) PFFileManager *fileManager;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileManager:(PFFileManager *)fileManager
                            options:(PFOfflineStoreOptions)options NS_DESIGNATED_INITIALIZER;

///--------------------------------------
/// @name Fetch
///--------------------------------------

- (BFTask *)fetchObjectLocallyAsync:(PFObject *)object;

/**
 Gets the data for the given object from the offline database. Returns a task that will be
 completed if data for the object was available. If the object is not in the cache, the task
 will be faulted, with a CACHE_MISS error.

 @param     object      The object to fetch.
 @param     database    A database connection to use.
 */
- (BFTask *)fetchObjectLocallyAsync:(PFObject *)object database:(PFSQLiteDatabase *)database;

///--------------------------------------
/// @name Save
///--------------------------------------

//TODO: (nlutsenko) Remove `includChildren` method, replace with PFLocalStore that wraps OfflineStore + Pin.
- (BFTask *)saveObjectLocallyAsync:(PFObject *)object includeChildren:(BOOL)includeChildren;
- (BFTask *)saveObjectLocallyAsync:(PFObject *)object withChildren:(NSArray *)children;

/**
 Stores an object (and optionally, every object it points to recursively) in the local database.
 If any of the objects have not been fetched from Parse, they will not be stored. However, if
 they have changed data, the data will be retained. To get the objects back later, you can use a
 ParseQuery with a cache policy that uses the local cache, or you can create an unfetched
 pointer with ParseObject.createWithoutData() and then call fetchFromLocalDatastore() on it.
 If you modify the object after saving it locally, such as by fetching it or saving it,
 those changes will automatically be applied to the cache.

 @param object   The root of the objects to save.
 @param children If non-empty - these children will be saved to LDS as well.
 @param database A database connection to use.
 */
- (BFTask *)saveObjectLocallyAsync:(PFObject *)object
                      withChildren:(NSArray *)children
                          database:(PFSQLiteDatabase *)database;

///--------------------------------------
/// @name Find
///--------------------------------------

/**
 Runs a PFQueryState against the store's contents.

 @return The objects that match the query's constraint.
 */
- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin;

/**
 Runs a PFQueryState against the store's contents.

 @return The count of objects that match the query's constraint.
 */
- (BFTask *)countAsyncForQueryState:(PFQueryState *)queryState
                               user:(PFUser *)user
                                pin:(PFPin *)pin;

/**
 Runs a PFQueryState against the store's contents.

 @return The objects that match the query's constraint.
 */
- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin
                           isCount:(BOOL)isCount;

/**
 Runs a PFQueryState against the store's contents. May cause any instances of the object to get fetched from
 offline database. (TODO (hallucinogen): should we consider objects in memory but not in Offline Store?)

 @param queryState       The query.
 @param user        The user making the query.
 @param pin         (Optional) The pin we're querying across. If null, all pins.
 @param isCount     YES if we're doing count.
 @param database    The PFSQLiteDatabase

 @return The objects that match the query's constraint.
 */
- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin
                           isCount:(BOOL)isCount
                          database:(PFSQLiteDatabase *)database;

///--------------------------------------
/// @name Update Internal State
///--------------------------------------

/**
 Takes an object that has been fetched from the database before and updates it with whatever
 data is in memory. This will only be used when data comes back from the server after a fetch
 or a save.
 */
- (BFTask *)updateDataForObjectAsync:(PFObject *)object;

///--------------------------------------
/// @name Delete
///--------------------------------------

/**
 Deletes the given object from Offline Store's pins
 */
- (BFTask *)deleteDataForObjectAsync:(PFObject *)object;

///--------------------------------------
/// @name Unpin
///--------------------------------------

- (BFTask *)unpinObjectAsync:(PFObject *)object;

///--------------------------------------
/// @name Internal Helper Methods
///--------------------------------------

/**
 Gets the UUID for the given object, if it has one. Otherwise, creates a new UUID for the object
 and adds a new row to the database for the object with no data.
 */
- (BFTask *)getOrCreateUUIDAsyncForObject:(PFObject *)object
                                 database:(PFSQLiteDatabase *)database;

/**
 This should only be called from `PFObject.objectWithoutDataWithClassName`.

 @return an object from OfflineStore cache. If nil is returned the object is not found in the cache.
 */
- (PFObject *)getOrCreateObjectWithoutDataWithClassName:(NSString *)className
                                               objectId:(NSString *)objectId;

/**
 When an object is finished saving, it gets an objectId. Then it should call this method to
 clean up the bookeeping around ids.
 */
- (void)updateObjectIdForObject:(PFObject *)object
                    oldObjectId:(NSString *)oldObjectId
                    newObjectId:(NSString *)newObjectId;

///--------------------------------------
/// @name Unit Test Helper Methods
///--------------------------------------

/**
 Used in unit testing only. Clears all in-memory caches so that data must be retrieved from disk.
 */
- (void)simulateReboot;

/**
 Used in unit testing only. Clears the database on disk.
 */
- (void)clearDatabase;

@end
