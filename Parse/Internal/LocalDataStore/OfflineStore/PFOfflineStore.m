/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOfflineStore.h"

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFErrorUtilities.h"
#import "PFFileManager.h"
#import "PFJSONSerialization.h"
#import "PFObjectPrivate.h"
#import "PFOfflineQueryLogic.h"
#import "PFPin.h"
#import "PFQueryPrivate.h"
#import "PFSQLiteDatabase.h"
#import "PFSQLiteDatabaseController.h"
#import "PFSQLiteDatabaseResult.h"
#import "PFUser.h"
#import "PFWeakValue.h"
#import "Parse_Private.h"

typedef BFTask *(^PFOfflineStoreDatabaseExecutionBlock)(PFSQLiteDatabase *database);

NSString *const PFOfflineStoreDatabaseName = @"ParseOfflineStore";

NSString *const PFOfflineStoreTableOfObjects = @"ParseObjects";
NSString *const PFOfflineStoreKeyOfClassName = @"className";
NSString *const PFOfflineStoreKeyOfIsDeletingEventually = @"isDeletingEventually";
NSString *const PFOfflineStoreKeyOfJSON = @"json";
NSString *const PFOfflineStoreKeyOfObjectId = @"objectId";
NSString *const PFOfflineStoreKeyOfUUID = @"uuid";

NSString *const PFOfflineStoreTableOfDependencies = @"Dependencies";
NSString *const PFOfflineStoreKeyOfKey = @"key";

int const PFOfflineStoreMaximumSQLVariablesCount = 999;

@interface PFOfflineStore ()

@property (nonatomic, assign, readwrite) PFOfflineStoreOptions options;

@property (nonatomic, strong, readonly) NSObject *lock;

/*!
 In-memory map of (className, objectId) to ParseObject. This is used so that we can
 always return the same instance for a given object. Objects in this map may or may
 not be in the database.
 */
@property (nonatomic, strong, readonly) NSMapTable *classNameAndObjectIdToObjectMap;

/*!
 In-memory set of ParseObjects that have been fetched from local database already.
 If the object is in the map, a fetch of it has been started. If the value is a
 finished task, then the fetch was completed.
 */
@property (nonatomic, strong, readonly) NSMapTable *fetchedObjects;

/*!
 In-memory map of ParseObject to UUID. This is used so that we can always return
 the same instance for a given object. Objects in this map may or may not be in the
 database.
 */
@property (nonatomic, strong, readonly) NSMapTable *objectToUUIDMap;

/*!
 In-memory map of UUID to ParseObject. This is used so we can always return
 the same instance for a given object. The only objects in this map are ones that
 are in database.
 */
@property (nonatomic, strong, readonly) NSMapTable *UUIDToObjectMap;

@property (nonatomic, strong, readonly) PFOfflineQueryLogic *offlineQueryLogic;

@property (nonatomic, strong, readonly) PFSQLiteDatabaseController *databaseController;

@end

@implementation PFOfflineStore

@synthesize offlineQueryLogic = _offlineQueryLogic;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithFileManager:(PFFileManager *)fileManager options:(PFOfflineStoreOptions)options {
    self = [super init];
    if (!self) return nil;

    _options = options;
    _fileManager = fileManager;
    _databaseController = [PFSQLiteDatabaseController controllerWithFileManager:_fileManager];
    _lock = [[NSObject alloc] init];
    _classNameAndObjectIdToObjectMap = [NSMapTable strongToWeakObjectsMapTable];
    _fetchedObjects = [NSMapTable weakToStrongObjectsMapTable];
    // This is a bit different from what we have in Android. The reason is because the object is quickly
    // retained by the OS and we depend on this MapTable to fetch the `uuidTask` of the object.
    _objectToUUIDMap = [NSMapTable weakToStrongObjectsMapTable];
    _UUIDToObjectMap = [NSMapTable strongToWeakObjectsMapTable];

    [[self class] _initializeTablesInBackgroundWithDatabaseController:_databaseController];

    return self;
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchObjectLocallyAsync:(PFObject *)object {
    __block BFTask *fetchTask = nil;
    return [[self _performDatabaseOperationAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        // We need this to return the result of `fetchObjectLocallyAsync` instead of returning the
        // result of `[database closeAsync]`
        fetchTask = [self fetchObjectLocallyAsync:object database:database];
        return fetchTask;
    }] continueWithBlock:^id(BFTask *task) {
        return fetchTask;
    }];
}

- (BFTask *)fetchObjectLocallyAsync:(PFObject *)object database:(PFSQLiteDatabase *)database {
    BFTaskCompletionSource *tcs = [BFTaskCompletionSource taskCompletionSource];
    BFTask *uuidTask = nil;

    @synchronized (self.lock) {
        BFTask *fetchTask = [self.fetchedObjects objectForKey:object];
        if (fetchTask && !(self.options & PFOfflineStoreOptionAlwaysFetchFromSQLite)) {
            // The object has been fetched from offline store, so any data that's in there
            // is already reflected in the in-memory version. There's nothing more to do.
            return [fetchTask continueWithBlock:^id(BFTask *task) {
                return [BFTask taskWithResult:[task.result weakObject]];
            }];
        }

        // Put a placeholder so that anyone else who attempts to fetch this object will just
        // wait for this call to finish doing it.
        [self.fetchedObjects setObject:[tcs.task continueWithBlock:^id(BFTask *task) {
            return [BFTask taskWithResult:[PFWeakValue valueWithWeakObject:task.result]];
        }] forKey:object];
        uuidTask = [self.objectToUUIDMap objectForKey:object];
    }
    NSString *className = [object parseClassName];
    NSString *objectId = [object objectId];

    // If this gets set, then it will contain data from offline store that need to be merged
    // into existing object in memory
    BFTask *jsonStringTask = [BFTask taskWithResult:nil];
    __block NSString *uuid = nil;

    if (objectId == nil) {
        // This object has never been saved to Parse
        if (uuidTask == nil) {
            // This object was not pulled from the datastore or previously saved to it.
            // There's nothing that can be fetched from it. This isn't an error, because it's
            // really convenient to try to fetch objects from offline store just to make sure
            // they're up-to-date, and we shouldn't force developers to specially handle this case.
        } else {
            // This object is a new ParseObject that is known to the datastore, but hasn't been
            // fetched. The only way this could happen is if the object had previously been stored
            // in the offline store, then the object was removed from memory (maybe by rebooting),
            // and then an object with a pointer to it was fetched, so we only created the pointer.
            // We need to pull the data out of the database using UUID.

            jsonStringTask = [[uuidTask continueWithSuccessBlock:^id(BFTask *task) {
                uuid = task.result;
                NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?;",
                                   PFOfflineStoreKeyOfJSON, PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID];
                return [database executeQueryAsync:query
                              withArgumentsInArray:[NSArray arrayWithObjects:uuid, nil]];
            }] continueWithSuccessBlock:^id(BFTask *task) {
                PFSQLiteDatabaseResult *result = task.result;
                if (![result next]) {
                    [result close];
                    [NSException raise:NSInternalInconsistencyException
                                format:@"Attempted to find non-existent uuid %@.", uuid];
                }
                NSString *jsonString = [result stringForColumnIndex:0];
                [result close];

                return jsonString;
            }];
        }
    } else {
        if (uuidTask && !(self.options & PFOfflineStoreOptionAlwaysFetchFromSQLite)) {
            // This object is an existing ParseObject, and we must've already pulled its data
            // out of the offline store, or else we wouldn't know its UUID. This should never happen.
            NSString *message = @"Object must have already been fetched but isn't marked as fetched.";
            [tcs setException:[NSException exceptionWithName:NSInternalInconsistencyException
                                                      reason:message
                                                    userInfo:nil]];

            @synchronized (self.lock) {
                [self.fetchedObjects removeObjectForKey:object];
            }
            return tcs.task;
        }

        // We've got a pointer to an existing ParseObject, but we've never pulled its data out of
        // the offline store. Since fetching from the server forces a fetch from the offline
        // store, that means this is a pointer. We need to try to find any existing entry for this
        // object in the database.
        NSString *query = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ = ? AND %@ = ?;",
                           PFOfflineStoreKeyOfJSON, PFOfflineStoreKeyOfUUID,
                           PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfClassName,
                           PFOfflineStoreKeyOfObjectId];
        NSArray *args = @[ className, objectId ];
        jsonStringTask = [[database executeQueryAsync:query
                                 withArgumentsInArray:args] continueWithSuccessBlock:^id(BFTask *task) {
            PFSQLiteDatabaseResult *result = task.result;
            if (![result next]) {
                NSString *errorMessage = @"This object is not available in the offline cache.";
                NSError *error = [PFErrorUtilities errorWithCode:kPFErrorCacheMiss
                                                         message:errorMessage
                                                       shouldLog:NO];
                [result close];
                return [BFTask taskWithError:error];
            }

            NSString *jsonString = [result stringForColumnIndex:0];
            NSString *newUUID = [result stringForColumnIndex:1];
            [result close];

            @synchronized (self.lock) {
                // It's okay to put this object into the uuid map. No one will try to fetch it,
                // because it's already in the fetchedObjects map. And no one will try to save it
                // without fetching it first, so everything should be fine.
                [self.objectToUUIDMap setObject:[BFTask taskWithResult:newUUID] forKey:object];
                [self.UUIDToObjectMap setObject:object forKey:newUUID];
            }
            return jsonString;
        }];
    }

    return [[jsonStringTask continueWithSuccessBlock:^id(BFTask *task) {
        NSString *jsonString = task.result;
        if (jsonString == nil) {
            // This means we tried to fetch from the database that was never actually saved
            // locally. This probably means that its parent object was saved locally and we
            // just created a pointer to this object. This should be considered cache miss.

            NSString *errorMessage = @"Attempted to fetch and object offline which was never "
            @"saved to the offline cache";
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorCacheMiss
                                                     message:errorMessage
                                                   shouldLog:NO];
            return [BFTask taskWithError:error];
        }
        id parsedJson = [PFJSONSerialization JSONObjectFromString:jsonString];
        NSMutableDictionary *offlineObjects = [[NSMutableDictionary alloc] init];
        [PFInternalUtils traverseObject:parsedJson usingBlock:^id(id object) {
            // Omit root and PFObject
            if ([object isKindOfClass:[NSDictionary class]] &&
                [((NSDictionary *)object)[@"__type"] isEqualToString:@"OfflineObject"] &&
                object != parsedJson) {
                NSString *uuid = ((NSDictionary *)object)[@"uuid"];
                offlineObjects[uuid] = [self _getPointerAsyncWithUUID:uuid database:database];
            }
            return object;
        }];

        NSArray *objectValues = [offlineObjects allValues];
        return [[BFTask taskForCompletionOfAllTasks:objectValues] continueWithSuccessBlock:^id(BFTask *task) {
            PFDecoder *decoder = [PFOfflineDecoder decoderWithOfflineObjects:offlineObjects];
            [object mergeFromRESTDictionary:parsedJson withDecoder:decoder];
            return [BFTask taskWithResult:nil];
        }];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.isCancelled) {
            [tcs cancel];
        } else if (task.error != nil) {
            [tcs setError:task.error];
        } else if (task.exception != nil) {
            [tcs setException:task.exception];
        } else {
            [tcs setResult:object];
        }
        return tcs.task;
    }];
}

///--------------------------------------
#pragma mark - Save
///--------------------------------------

- (BFTask *)saveObjectLocallyAsync:(PFObject *)object includeChildren:(BOOL)includeChildren {
    //TODO: (nlutsenko) Remove this method, replace with LocalStore implementation that wraps OfflineStore + Pin.
    return [self _performDatabaseTransactionAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        return [self saveObjectLocallyAsync:object includeChildren:includeChildren database:database];
    }];
}

- (BFTask *)saveObjectLocallyAsync:(PFObject *)object withChildren:(NSArray *)children {
    return [self _performDatabaseTransactionAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        return [self saveObjectLocallyAsync:object withChildren:children database:database];
    }];
}

- (BFTask *)saveObjectLocallyAsync:(PFObject *)object
                   includeChildren:(BOOL)includeChildren
                          database:(PFSQLiteDatabase *)database {
    //TODO: (nlutsenko) Remove this method, replace with LocalStore implementation that wraps OfflineStore + Pin.
    NSMutableArray *children = nil;
    if (includeChildren) {
        children = [NSMutableArray array];
        [PFInternalUtils traverseObject:object usingBlock:^id(id traversedObject) {
            if ([traversedObject isKindOfClass:[PFObject class]]) {
                [children addObject:traversedObject];
            }
            return traversedObject;
        }];
    }
    return [self saveObjectLocallyAsync:object withChildren:children database:database];
}

- (BFTask *)saveObjectLocallyAsync:(PFObject *)object
                      withChildren:(NSArray *)children
                          database:(PFSQLiteDatabase *)database {
    //TODO (nlutsenko): Add assert that checks whether all children are actually children of an object.
    NSMutableArray *objectsInTree = nil;
    if (children == nil) {
        objectsInTree = [NSMutableArray arrayWithObject:object];
    } else {
        objectsInTree = [children mutableCopy];
        if (![objectsInTree containsObject:object]) {
            [objectsInTree addObject:object];
        }
    }

    // Call saveObjectLocallyAsync for each of them individually
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    for (PFObject *objInTree in objectsInTree) {
        [tasks addObject:[self fetchObjectLocallyAsync:objInTree database:database]];
    }

    return [[[[[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
        return [self.objectToUUIDMap objectForKey:object];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSString *uuid = task.result;
        if (uuid == nil) {
            // The root object was never stored in offline store, so nothing unpin.
            return [BFTask taskWithResult:nil];
        }

        // Delete all objects locally corresponding to the key we're trying to use in case it was
        // used before (overwrite)
        return [self _unpinKeyAsync:uuid database:database];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return [self getOrCreateUUIDAsyncForObject:object database:database];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSString *uuid = task.result;

        NSMutableArray *tasks = [[NSMutableArray alloc] init];
        for (PFObject *object in objectsInTree) {
            [tasks addObject:[self saveObjectLocallyAsync:object key:uuid database:database]];
        }

        return [BFTask taskForCompletionOfAllTasks:tasks];
    }];
}

- (BFTask *)saveObjectLocallyAsync:(PFObject *)object
                               key:(NSString *)key
                          database:(PFSQLiteDatabase *)database {
    if ([object objectId] != nil && ![object isDataAvailable] &&
        ![object _hasChanges] && ![object _hasOutstandingOperations]) {
        return [BFTask taskWithResult:nil];
    }

    __block NSString *uuid = nil;
    __block id encoded = nil;
    return [[[[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        // Make sure we have UUID for the object to be saved.
        return [self getOrCreateUUIDAsyncForObject:object database:database];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        uuid = task.result;

        // Encode the object, and wait for the UUIDs in its pointers to get encoded.
        PFOfflineObjectEncoder *encoder = [PFOfflineObjectEncoder objectEncoderWithOfflineStore:self database:database];
        // We don't care about operationSetUUIDs here
        NSArray *operationSetUUIDs = nil;
        encoded = [object RESTDictionaryWithObjectEncoder:encoder operationSetUUIDs:&operationSetUUIDs];
        return [encoder encodeFinished];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // Time to actually save the object
        NSString *className = [object parseClassName];
        NSString *objectId = [object objectId];
        NSString *encodedString = [PFJSONSerialization stringFromJSONObject:encoded];
        NSString *updateFields = nil;
        NSArray *queryParams = nil;

        if (objectId != nil) {
            updateFields = [NSString stringWithFormat:@"%@ = ?, %@ = ?, %@ = ?",
                            PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfJSON,
                            PFOfflineStoreKeyOfObjectId];
            queryParams = @[className, encodedString, objectId, uuid];
        } else {
            updateFields = [NSString stringWithFormat:@"%@ = ?, %@ = ?",
                            PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfJSON];
            queryParams = @[className, encodedString, uuid];
        }

        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?",
                         PFOfflineStoreTableOfObjects, updateFields,
                         PFOfflineStoreKeyOfUUID];
        return [database executeSQLAsync:sql withArgumentsInArray:queryParams];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSString *sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO %@(%@, %@) VALUES (?, ?)",
                         PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfKey,
                         PFOfflineStoreKeyOfUUID];
        return [database executeSQLAsync:sql withArgumentsInArray:@[key, uuid]];
    }];
}

///--------------------------------------
#pragma mark - Find
///--------------------------------------

- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin {
    return [self findAsyncForQueryState:queryState user:user pin:pin isCount:NO];
}

- (BFTask *)countAsyncForQueryState:(PFQueryState *)queryState
                               user:(PFUser *)user
                                pin:(PFPin *)pin {
    return [[self findAsyncForQueryState:queryState
                                    user:user
                                     pin:pin
                                 isCount:YES] continueWithSuccessBlock:^id(BFTask *task) {
        if (!task.cancelled && !task.error && !task.exception) {
            NSArray *result = task.result;
            return @(result.count);
        }
        return task;
    }];
}

- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin
                           isCount:(BOOL)isCount {
    __block BFTask *resultTask = nil;
    return [[self _performDatabaseOperationAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        resultTask = [self findAsyncForQueryState:queryState user:user pin:pin isCount:isCount database:database];
        return resultTask;
    }] continueWithBlock:^id(BFTask *ignored) {
        // We need this to return the result of `findQuery` instead of returning the
        // result of `[database closeAsync]`
        return resultTask;
    }];
}

- (BFTask *)findAsyncForQueryState:(PFQueryState *)queryState
                              user:(PFUser *)user
                               pin:(PFPin *)pin
                           isCount:(BOOL)isCount
                          database:(PFSQLiteDatabase *)database {
    __block NSMutableArray *mutableResults = [NSMutableArray array];
    BFTask *queryTask = nil;
    BOOL includeIsDeletingEventually = queryState.shouldIncludeDeletingEventually;

    if (pin == nil) {
        NSString *isDeletingEventuallyQuery = @"";
        if (!includeIsDeletingEventually) {
            isDeletingEventuallyQuery = [NSString stringWithFormat:@"AND %@ = 0",
                                         PFOfflineStoreKeyOfIsDeletingEventually];
        }
        NSString *queryString = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? %@;",
                                 PFOfflineStoreKeyOfUUID, PFOfflineStoreTableOfObjects,
                                 PFOfflineStoreKeyOfClassName, isDeletingEventuallyQuery];
        queryTask = [database executeQueryAsync:queryString withArgumentsInArray:@[ queryState.parseClassName ]];
    } else {
        BFTask *uuidTask = [self.objectToUUIDMap objectForKey:pin];
        if (uuidTask == nil) {
            // Pin was never saved locally, therefore there won't be any results.
            return [BFTask taskWithResult:mutableResults];
        }

        queryTask = [uuidTask continueWithSuccessBlock:^id(BFTask *task) {
            NSString *uuid = task.result;
            NSString *isDeletingEventuallyQuery = @"";
            if (!includeIsDeletingEventually) {
                isDeletingEventuallyQuery = [NSString stringWithFormat:@"AND %@ = 0",
                                             PFOfflineStoreKeyOfIsDeletingEventually];
            }
            NSString *queryString = [NSString stringWithFormat:@"SELECT A.%@ FROM %@ A "
                                     @"INNER JOIN %@ B ON A.%@ = B.%@ WHERE %@ = ? AND %@ = ? %@;",
                                     PFOfflineStoreKeyOfUUID, PFOfflineStoreTableOfObjects,
                                     PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfUUID,
                                     PFOfflineStoreKeyOfUUID, PFOfflineStoreKeyOfClassName,
                                     PFOfflineStoreKeyOfKey, isDeletingEventuallyQuery];

            return [database executeQueryAsync:queryString
                          withArgumentsInArray:@[ queryState.parseClassName, uuid ]];
        }];
    }

    @weakify(self);
    return [[queryTask continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFSQLiteDatabaseResult *result = task.result;

        PFConstraintMatcherBlock matcherBlock = [self.offlineQueryLogic createMatcherForQueryState:queryState
                                                                                              user:user];

        BFTask *checkAllObjectsTask = [BFTask taskWithResult:nil];
        while ([result next]) {
            NSString *uuid = [result stringForColumnIndex:0];
            __block PFObject *object = nil;

            checkAllObjectsTask = [[[[checkAllObjectsTask continueWithSuccessBlock:^id(BFTask *task) {
                return [self _getPointerAsyncWithUUID:uuid database:database];
            }] continueWithSuccessBlock:^id(BFTask *task) {
                object = task.result;
                return [self fetchObjectLocallyAsync:object database:database];
            }] continueWithSuccessBlock:^id(BFTask *task) {
                if (!object.isDataAvailable) {
                    return [BFTask taskWithResult:@NO];
                }
                return matcherBlock(object, database);
            }] continueWithSuccessBlock:^id(BFTask *task) {
                if ([task.result boolValue]) {
                    [mutableResults addObject:object];
                }
                return [BFTask taskWithResult:nil];
            }];
        }
        [result close];

        return checkAllObjectsTask;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);

        // Sort, Apply Skip and Limit

        PFOfflineQueryOption queryOptions = 0;
        if (!isCount) {
            queryOptions = PFOfflineQueryOptionOrder | PFOfflineQueryOptionSkip | PFOfflineQueryOptionLimit;
        }
        NSArray *results = [self.offlineQueryLogic resultsByApplyingOptions:queryOptions
                                                               ofQueryState:queryState
                                                                  toResults:mutableResults];

        // Fetch includes
        BFTask *fetchIncludesTask = [self.offlineQueryLogic fetchIncludesAsyncForResults:results
                                                                            ofQueryState:queryState
                                                                              inDatabase:database];

        return [fetchIncludesTask continueWithSuccessBlock:^id(BFTask *task) {
            return results;
        }];
    }];
}

///--------------------------------------
#pragma mark - Update
///--------------------------------------

- (BFTask *)updateDataForObjectAsync:(PFObject *)object {
    BFTask *fetchTask = nil;

    @synchronized (self.lock) {
        fetchTask = [self.fetchedObjects objectForKey:object];
        if (!fetchTask) {
            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                             reason:@"An object cannot be updated if it wasn't fetched"
                                                           userInfo:nil];
            return [BFTask taskWithException:exception];
        }
    }
    return [fetchTask continueWithBlock:^id(BFTask *task) {
        if (task.error != nil) {
            // Catch CACHE_MISS errors and ignore them.
            if (task.error.code == kPFErrorCacheMiss) {
                return [BFTask taskWithResult:nil];
            }
            return [BFTask taskWithResult:[task.result weakObject]];
        }

        return [self _performDatabaseTransactionAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
            return [self _updateDataForObjectAsync:object inDatabase:database];
        }];
    }];
}

- (BFTask *)_updateDataForObjectAsync:(PFObject *)object inDatabase:(PFSQLiteDatabase *)database {
    BFTask *uuidTask = nil;
    @synchronized (self.lock) {
        uuidTask = [self.objectToUUIDMap objectForKey:object];
        if (!uuidTask) {
            // It was fetched, but it has no UUID. That must mean it isn't actually in the database.
            return [BFTask taskWithResult:nil];
        }
    }

    __block NSString *uuid = nil;
    __block NSDictionary *dataDictionary = nil;
    return [[uuidTask continueWithSuccessBlock:^id(BFTask *task) {
        uuid = task.result;

        PFOfflineObjectEncoder *encoder = [PFOfflineObjectEncoder objectEncoderWithOfflineStore:self
                                                                                       database:database];
        NSArray *operationSetUUIDs = nil;
        dataDictionary = [object RESTDictionaryWithObjectEncoder:encoder operationSetUUIDs:&operationSetUUIDs];
        return [encoder encodeFinished];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // Put it in database
        NSString *className = object.parseClassName;
        NSString *objectId = object.objectId;
        NSString *encodedDataDictionary = [PFJSONSerialization stringFromJSONObject:dataDictionary];
        NSNumber *deletingEventually = dataDictionary[PFOfflineStoreKeyOfIsDeletingEventually];

        NSString *updateParams = nil;
        NSArray *updateArguments = nil;
        if (objectId != nil) {
            updateParams = [NSString stringWithFormat:@"%@ = ?, %@ = ?, %@ = ?, %@ = ?",
                            PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfJSON,
                            PFOfflineStoreKeyOfIsDeletingEventually, PFOfflineStoreKeyOfObjectId];
            updateArguments = @[ className, encodedDataDictionary, deletingEventually, objectId, uuid ];
        } else {
            updateParams = [NSString stringWithFormat:@"%@ = ?, %@ = ?, %@ = ?",
                            PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfJSON,
                            PFOfflineStoreKeyOfIsDeletingEventually];
            updateArguments = @[ className, encodedDataDictionary, deletingEventually, uuid ];
        }

        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?",
                         PFOfflineStoreTableOfObjects, updateParams, PFOfflineStoreKeyOfUUID];

        return [database executeSQLAsync:sql withArgumentsInArray:updateArguments];
    }];
}

///--------------------------------------
#pragma mark - Delete
///--------------------------------------

- (BFTask *)deleteDataForObjectAsync:(PFObject *)object {
    return [self _performDatabaseTransactionAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        return [self deleteDataForObjectAsync:object database:database];
    }];
}

- (BFTask *)deleteDataForObjectAsync:(PFObject *)object database:(PFSQLiteDatabase *)database {
    __block NSString *uuid = nil;

    // Make sure the object has a UUID.
    BFTask *uuidTask = nil;
    @synchronized (self.lock) {
        uuidTask = [self.objectToUUIDMap objectForKey:object];
        if (!uuidTask) {
            // It was fetched, but it has no UUID. That must mean it isn't actually in the database.
            return [BFTask taskWithResult:nil];
        }
    }

    uuidTask = [uuidTask continueWithSuccessBlock:^id(BFTask *task) {
        uuid = task.result;
        return task;
    }];

    // If the object was the root of a pin, unpin it.
    BFTask *unpinTask = [[uuidTask continueWithSuccessBlock:^id(BFTask *task) {
        // Find all the roots for this object.
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?",
                         PFOfflineStoreKeyOfKey, PFOfflineStoreTableOfDependencies,
                         PFOfflineStoreKeyOfUUID];
        return [database executeQueryAsync:sql withArgumentsInArray:@[ uuid ]];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // Try to unpin this object from the pin label if it's a root of the PFPin.
        PFSQLiteDatabaseResult *result = task.result;
        NSMutableArray *tasks = [NSMutableArray array];

        while (result.next) {
            NSString *objectUUID = [result stringForColumnIndex:0];

            BFTask *getPointerTask = [self _getPointerAsyncWithUUID:objectUUID database:database];
            BFTask *objectUnpinTask = [[getPointerTask continueWithSuccessBlock:^id(BFTask *task) {
                PFPin *pin = task.result;
                return [self fetchObjectLocallyAsync:pin database:database];
            }] continueWithBlock:^id(BFTask *task) {
                PFPin *pin = task.result;

                NSMutableArray *modified = pin.objects;
                if (modified == nil || ![modified containsObject:object]) {
                    return task;
                }

                [modified removeObject:object];
                if (modified.count == 0) {
                    return [self _unpinKeyAsync:objectUUID database:database];
                }
                pin.objects = modified;

                return [self saveObjectLocallyAsync:pin includeChildren:YES database:database];
            }];
            [tasks addObject:objectUnpinTask];
        }
        [result close];

        return [BFTask taskForCompletionOfAllTasks:tasks];
    }];

    return [[[unpinTask continueWithSuccessBlock:^id(BFTask *task) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                         PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfUUID];
        return [database executeSQLAsync:sql withArgumentsInArray:@[ uuid ]];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                         PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID];
        return [database executeSQLAsync:sql withArgumentsInArray:@[ uuid ]];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // Delete the object from memory cache.
        // (or else `PFObject.objectWithoutDataWithClassName` will return a valid object)
        @synchronized (self.lock) {
            // TODO (hallucinogen): we should probably clean up UUIDToObjectMap and objectToUUIDMap
            // but getting the uuid requires a task and things might get a little funky...
            if (object.objectId != nil) {
                NSString *key = [self _generateKeyForClassName:object.parseClassName objectId:object.objectId];
                [self.classNameAndObjectIdToObjectMap removeObjectForKey:key];
            }
            [self.fetchedObjects removeObjectForKey:object];
        }
        return task;
    }];
}

///--------------------------------------
#pragma mark - Unpin
///--------------------------------------

- (BFTask *)unpinObjectAsync:(PFObject *)object {
    BFTask *uuidTask = [self.objectToUUIDMap objectForKey:object];
    return [uuidTask continueWithBlock:^id(BFTask *task) {
        NSString *uuid = task.result;
        if (!uuid) {
            // The root object was never stored in the offline store, so nothing to unpin.
            return [BFTask taskWithResult:nil];
        }
        return [self _unpinKeyAsync:uuid];
    }];
}

- (BFTask *)_unpinKeyAsync:(NSString *)key {
    return [self _performDatabaseTransactionAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        return [self _unpinKeyAsync:key database:database];
    }];
}

- (BFTask *)_unpinKeyAsync:(NSString *)key database:(PFSQLiteDatabase *)database {
    NSMutableArray *uuidsToDelete = [NSMutableArray array];
    // Fetch all uuids from Dependencies for key=? grouped by uuid having a count of 1
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ IN "
                       @"(SELECT %@ FROM %@ GROUP BY %@ HAVING COUNT(%@) = 1);",
                       PFOfflineStoreKeyOfUUID, PFOfflineStoreTableOfDependencies,
                       PFOfflineStoreKeyOfKey, PFOfflineStoreKeyOfUUID, PFOfflineStoreKeyOfUUID,
                       PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfUUID,
                       PFOfflineStoreKeyOfUUID];
    return [[[[database executeQueryAsync:query
                     withArgumentsInArray:@[ key ]] continueWithSuccessBlock:^id(BFTask *task) {
        // DELETE FROM Objects
        PFSQLiteDatabaseResult *result = task.result;
        while (result.next) {
            [uuidsToDelete addObject:[result stringForColumnIndex:0]];
        }
        [result close];

        return [self _deleteObjectsWithUUIDs:uuidsToDelete database:database];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // DELETE FROM Dependencies
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                         PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfKey];
        return [database executeSQLAsync:sql withArgumentsInArray:@[ key ]];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @synchronized (self.lock) {
            // Remove uuids from memory
            for (NSString *uuid in uuidsToDelete) {
                PFObject *object = [self.UUIDToObjectMap objectForKey:uuid];
                if (object != nil) {
                    [self.objectToUUIDMap removeObjectForKey:object];
                    [self.UUIDToObjectMap removeObjectForKey:uuid];
                }
            }
        }
        return [BFTask taskWithResult:nil];
    }];
}

- (BFTask *)_deleteObjectsWithUUIDs:(NSArray *)uuids database:(PFSQLiteDatabase *)database {
    if (uuids.count <= 0) {
        return [BFTask taskWithResult:nil];
    }

    if (uuids.count > PFOfflineStoreMaximumSQLVariablesCount) {
        NSRange range = NSMakeRange(0, PFOfflineStoreMaximumSQLVariablesCount);
        return [[self _deleteObjectsWithUUIDs:[uuids subarrayWithRange:range]
                                     database:database] continueWithSuccessBlock:^id(BFTask *task) {
            unsigned long includedCount = uuids.count - PFOfflineStoreMaximumSQLVariablesCount;
            NSRange range = NSMakeRange(PFOfflineStoreMaximumSQLVariablesCount, includedCount);
            return [self _deleteObjectsWithUUIDs:[uuids subarrayWithRange:range] database:database];
        }];
    }

    NSMutableArray *placeholders = [NSMutableArray array];
    for (int i = 0; i < uuids.count; ++i) {
        [placeholders addObject:@"?"];
    }
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@);",
                     PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID,
                     [placeholders componentsJoinedByString:@","]];
    return [database executeSQLAsync:sql withArgumentsInArray:uuids];
}

///--------------------------------------
#pragma mark - Internal Helper Methods
///--------------------------------------

- (BFTask *)getOrCreateUUIDAsyncForObject:(PFObject *)object
                                 database:(PFSQLiteDatabase *)database {
    NSString *newUUID = [[NSUUID UUID] UUIDString];
    BFTaskCompletionSource *tcs = [BFTaskCompletionSource taskCompletionSource];

    @synchronized (self.lock) {
        BFTask *uuidTask = [self.objectToUUIDMap objectForKey:object];
        if (uuidTask != nil) {
            // Return existing task.
            return uuidTask;
        }

        // The object doesn't have UUID yet, so we're gonna have to make one
        [self.objectToUUIDMap setObject:tcs.task forKey:object];
        [self.UUIDToObjectMap setObject:object forKey:newUUID];

        __weak id weakObject = object;
        [self.fetchedObjects setObject:[tcs.task continueWithSuccessBlock:^id(BFTask *task) {
            return [PFWeakValue valueWithWeakObject:weakObject];
        }] forKey:object];
    }

    // We need to put a placeholder row in the database so that later on the save can be just
    // an update. This could be a pointer to an object that itself never gets saved offline,
    // in which case the consumer will just have to deal with that.
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@(%@, %@) VALUES(?, ?);",
                       PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID, PFOfflineStoreKeyOfClassName];
    [[database executeSQLAsync:query
          withArgumentsInArray:@[ newUUID, [object parseClassName]]] continueWithSuccessBlock:^id(BFTask *task) {
        [tcs setResult:newUUID];
        return [BFTask taskWithResult:nil];
    }];

    return tcs.task;
}

/*!
 Gets an unfetched pointer to an object in the database, based on its uuid. The object may or may
 not be in memory, but it must be in database. If it is already in memory, the instance will be
 returned. Since this is only for creating pointers to objects that are referenced by other objects
 in the datastore, it's a fair assumption.

 @param uuid        The UUID of the object to retrieve.
 @param database    The database instance to retrieve from.
 @returns The object with that UUID.
 */
- (BFTask *)_getPointerAsyncWithUUID:(NSString *)uuid
                            database:(PFSQLiteDatabase *)database {
    @synchronized (self.lock) {
        PFObject *existing = [self.UUIDToObjectMap objectForKey:uuid];
        if (existing != nil) {
            return [BFTask taskWithResult:existing];
        }
    }

    // We only want the pointer, but we have to look in the database to know if there's something
    // with this classname and object id already.
    NSString *query = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ = ?;",
                       PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfObjectId,
                       PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID];
    return [[database executeQueryAsync:query
                   withArgumentsInArray:@[ uuid ]] continueWithSuccessBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        if (![result next]) {
            [result close];
            [NSException raise:NSInternalInconsistencyException
                        format:@"Attempted to find non-existent uuid %@", uuid];
        }

        @synchronized (self.lock) {
            PFObject *existing = [self.UUIDToObjectMap objectForKey:uuid];
            if (existing != nil) {
                [result close];
                return existing;
            }

            NSString *className = [result stringForColumnIndex:0];
            NSString *objectId = [result stringForColumnIndex:1];
            [result close];

            PFObject *pointer = [PFObject objectWithoutDataWithClassName:className objectId:objectId];

            // If it doesn't have objectId, we don't really need the UUID, and this simplifies some
            // other logic elsewhere if we only update the map for new objects.
            if (objectId == nil) {
                [self.UUIDToObjectMap setObject:pointer forKey:uuid];
                [self.objectToUUIDMap setObject:[BFTask taskWithResult:uuid] forKey:pointer];
            }
            return pointer;
        }
    }];
}

- (PFObject *)getOrCreateObjectWithoutDataWithClassName:(NSString *)className
                                               objectId:(NSString *)objectId {
    PFParameterAssert(objectId, @"objectId cannot be nil.");

    PFObject *object = nil;
    @synchronized (self.lock) {
        NSString *key = [self _generateKeyForClassName:className objectId:objectId];
        object = [self.classNameAndObjectIdToObjectMap objectForKey:key];
        if (!object) {
            object = [PFObject objectWithClassName:className objectId:objectId completeData:NO];
            [self updateObjectIdForObject:object oldObjectId:nil newObjectId:objectId];
        }
    }
    return object;
}

- (void)updateObjectIdForObject:(PFObject *)object
                    oldObjectId:(NSString *)oldObjectId
                    newObjectId:(NSString *)newObjectId {
    if (oldObjectId != nil) {
        if ([oldObjectId isEqualToString:newObjectId]) {
            return;
        }
        [NSException raise:NSInternalInconsistencyException format:@"objectIds cannot be changed in offline mode."];
    }

    NSString *className = object.parseClassName;
    NSString *key = [self _generateKeyForClassName:className objectId:newObjectId];

    @synchronized (self.lock) {
        // See if there's already an entry for new objectId.
        PFObject *existing = [self.classNameAndObjectIdToObjectMap objectForKey:key];
        PFConsistencyAssert(existing == nil || existing == object,
                            @"Attempted to change an objectId to one that's already known to the OfflineStore.");

        // Okay, all clear to add the new reference.
        [self.classNameAndObjectIdToObjectMap setObject:object forKey:key];
    }
}

- (NSString *)_generateKeyForClassName:(NSString *)className
                              objectId:(NSString *)objectId {
    return [NSString stringWithFormat:@"%@:%@", className, objectId];
}

// TODO (hallucinogen): is this the right way to store the schema?
+ (NSString *)PFOfflineStoreParseObjectsTableSchema {
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ("
            @"%@ TEXT PRIMARY KEY, "
            @"%@ TEXT NOT NULL, "
            @"%@ TEXT, "
            @"%@ TEXT, "
            @"%@ INTEGER DEFAULT 0, "
            @"UNIQUE(%@, %@));", PFOfflineStoreTableOfObjects, PFOfflineStoreKeyOfUUID,
            PFOfflineStoreKeyOfClassName, PFOfflineStoreKeyOfObjectId, PFOfflineStoreKeyOfJSON,
            PFOfflineStoreKeyOfIsDeletingEventually, PFOfflineStoreKeyOfClassName,
            PFOfflineStoreKeyOfObjectId];
}

+ (NSString *)PFOfflineStoreDependenciesTableSchema {
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ("
            @"%@ TEXT NOT NULL, "
            @"%@ TEXT NOT NULL, "
            @"PRIMARY KEY(%@, %@));", PFOfflineStoreTableOfDependencies, PFOfflineStoreKeyOfKey,
            PFOfflineStoreKeyOfUUID, PFOfflineStoreKeyOfKey, PFOfflineStoreKeyOfUUID];
}

+ (BFTask *)_initializeTablesInBackgroundWithDatabaseController:(PFSQLiteDatabaseController *)databaseController {
    return [[databaseController openDatabaseWithNameAsync:PFOfflineStoreDatabaseName] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabase *database = task.result;
        return [[[[[database beginTransactionAsync] continueWithSuccessBlock:^id(BFTask *task) {
            return [database executeSQLAsync:[self PFOfflineStoreParseObjectsTableSchema] withArgumentsInArray:nil];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            return [database executeSQLAsync:[self PFOfflineStoreDependenciesTableSchema] withArgumentsInArray:nil];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            return [database commitAsync];
        }] continueWithBlock:^id(BFTask *task) {
            return [database closeAsync];
        }];
    }];
}

///--------------------------------------
#pragma mark - Database Helpers
///--------------------------------------

- (BFTask *)_performDatabaseTransactionAsyncWithBlock:(PFOfflineStoreDatabaseExecutionBlock)block {
    return [self _performDatabaseOperationAsyncWithBlock:^BFTask *(PFSQLiteDatabase *database) {
        BFTask *task = [database beginTransactionAsync];
        task = [task continueWithSuccessBlock:^id(BFTask *task) {
            return block(database);
        }];
        return [task continueWithSuccessBlock:^id(BFTask *task) {
            return [database commitAsync];
        }];
    }];
}

- (BFTask *)_performDatabaseOperationAsyncWithBlock:(PFOfflineStoreDatabaseExecutionBlock)block {
    return [[self.databaseController openDatabaseWithNameAsync:PFOfflineStoreDatabaseName] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabase *database = task.result;
        return [block(database) continueWithBlock:^id(BFTask *task) {
            return [database closeAsync];
        }];
    }];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFOfflineQueryLogic *)offlineQueryLogic {
    @synchronized (self.lock) {
        if (!_offlineQueryLogic) {
            _offlineQueryLogic = [[PFOfflineQueryLogic alloc] initWithOfflineStore:self];
        }
        return _offlineQueryLogic;
    }
}

///--------------------------------------
#pragma mark - Unit Test helper
///--------------------------------------

- (void)simulateReboot {
    @synchronized (self.lock) {
        [self.UUIDToObjectMap removeAllObjects];
        [self.objectToUUIDMap removeAllObjects];
        [self.classNameAndObjectIdToObjectMap removeAllObjects];
        [self.fetchedObjects removeAllObjects];
    }
}

- (void)clearDatabase {
    // Delete DB file
    NSString *filePath = [self.fileManager parseDataItemPathForPathComponent:PFOfflineStoreDatabaseName];
    [[PFFileManager removeItemAtPathAsync:filePath] waitForResult:nil withMainThreadWarning:NO];

    // Reinitialize tables
    [PFOfflineStore _initializeTablesInBackgroundWithDatabaseController:self.databaseController];
}

@end
