/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectLocalIdStore.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFJSONSerialization.h"
#import "PFLogging.h"

static NSString *const _PFObjectLocalIdStoreDiskFolderPath = @"LocalId";

///--------------------------------------
#pragma mark - PFObjectLocalIdStoreMapEntry
///--------------------------------------

/**
 * Internal class representing all the information we know about a local id.
 */
@interface PFObjectLocalIdStoreMapEntry : NSObject

@property (nonatomic, strong) NSString *objectId;
@property (atomic, assign) int referenceCount;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFile:(NSString *)filePath;

@end

@implementation PFObjectLocalIdStoreMapEntry

- (instancetype)init {
    return [super init];
}

- (instancetype)initWithFile:(NSString *)filePath {
    self = [self init];
    if (!self) return nil;

    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:jsonData];

    _objectId = [dictionary[@"objectId"] copy];
    _referenceCount = [dictionary[@"referenceCount"] intValue];

    return self;
}

- (void)writeToFile:(NSString *)filePath {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"referenceCount"] = @(self.referenceCount);
    if (self.objectId) {
        dictionary[@"objectId"] = self.objectId;
    }

    NSData *jsonData = [PFJSONSerialization dataFromJSONObject:dictionary];
    [[PFFileManager writeDataAsync:jsonData toFile:filePath] waitForResult:nil withMainThreadWarning:NO];
}

@end

///--------------------------------------
#pragma mark - PFObjectLocalIdStore
///--------------------------------------

@interface PFObjectLocalIdStore () {
    NSString *_diskPath;
    NSObject *_lock;
    NSMutableDictionary *_inMemoryCache;
}

@end

@implementation PFObjectLocalIdStore

/**
 * Creates a new LocalIdManager with default options.
 */
- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _lock = [[NSObject alloc] init];
    _inMemoryCache = [NSMutableDictionary dictionary];

    // Construct the path to the disk storage directory.
    _diskPath = [dataSource.fileManager parseDataItemPathForPathComponent:_PFObjectLocalIdStoreDiskFolderPath];

    NSError *error = nil;
    [[PFFileManager createDirectoryIfNeededAsyncAtPath:_diskPath] waitForResult:&error withMainThreadWarning:NO];
    if (error) {
        PFLogError(PFLoggingTagCommon, @"Unable to create directories for local id storage with error: %@", error);
    }

    return self;
}

+ (instancetype)storeWithDataSource:(id<PFFileManagerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

/**
 * Returns Yes if localId has the right basic format for a local id.
 */
+ (BOOL)isLocalId:(NSString *)localId {
    if (localId.length != 22U) {
        return NO;
    }
    if (![localId hasPrefix:@"local_"]) {
        return NO;
    }
    for (int i = 6; i < localId.length; ++i) {
        if (!ishexnumber([localId characterAtIndex:i])) {
            return NO;
        }
    }
    return YES;
}

/**
 * Grabs one entry in the local id map off the disk.
 */
- (PFObjectLocalIdStoreMapEntry *)getMapEntry:(NSString *)localId error:(NSError * __autoreleasing *) error {

    PFPreconditionBailAndSetError([[self class] isLocalId:localId], error, nil, @"Tried to get invalid local id: \"%@\".", localId);

    PFObjectLocalIdStoreMapEntry *entry = nil;

    NSString *file = [_diskPath stringByAppendingPathComponent:localId];
    if (![[NSFileManager defaultManager] isReadableFileAtPath:file]) {
        entry = [[PFObjectLocalIdStoreMapEntry alloc] init];
    } else {
        entry = [[PFObjectLocalIdStoreMapEntry alloc] initWithFile:file];
    }

    // If there's an objectId in memory, make sure it matches the one in the
    // file. This is in case the id was retained on disk *after* it was resolved.
    if (!entry.objectId) {
        NSString *objectId = _inMemoryCache[localId];
        if (objectId) {
            entry.objectId = objectId;
            if (entry.referenceCount > 0) {
                if(![self putMapEntry:entry forLocalId:localId error:error]) {
                    return nil;
                }
            }
        }
    }

    return entry;
}

/**
 * Writes one entry to the local id map on disk.
 */
- (BOOL)putMapEntry:(PFObjectLocalIdStoreMapEntry *)entry forLocalId:(NSString *)localId error:(NSError * __autoreleasing *)error {
    PFPreconditionBailAndSetError([[self class] isLocalId:localId],error, NO, @"Tried to get invalid local id: \"%@\".", localId);

    NSString *file = [_diskPath stringByAppendingPathComponent:localId];
    [entry writeToFile:file];
    return YES;
}

/**
 * Removes an entry from the local id map on disk.
 */
- (BOOL)removeMapEntry:(NSString *)localId error:(NSError * __autoreleasing *)error {
    PFPreconditionBailAndSetError([[self class] isLocalId:localId], error, NO, @"Tried to get invalid local id: \"%@\".", localId);

    NSString *file = [_diskPath stringByAppendingPathComponent:localId];
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    return YES;
}

/**
 * Creates a new local id in the map.
 */
- (NSString *)createLocalId {
    @synchronized (_lock) {
        // Generate a new random string of upper and lower case letters.

        // Start by generating a number. It will be the localId as a base-52 number.
        // It has to be a uint64_t because log256(52^10) ~= 7.13 bytes.
        uint64_t localIdNumber = (((uint64_t)arc4random()) << 32) | ((uint64_t)arc4random());
        NSString *localId = [NSString stringWithFormat:@"local_%016llx", localIdNumber];

        PFConsistencyAssert([[self class] isLocalId:localId], @"Generated an invalid local id: \"%@\".", localId);

        return localId;
    }
}

/**
 * Increments the retain count of a local id on disk.
 */
- (BOOL)retainLocalIdOnDisk:(NSString *)localId error:(NSError **)error {
    @synchronized (_lock) {
        PFObjectLocalIdStoreMapEntry *entry = [self getMapEntry:localId error:error];
        if (!entry) {
            return NO;
        }
        entry.referenceCount++;
        return [self putMapEntry:entry forLocalId:localId error:error];
    }
}

/**
 * Decrements the retain count of a local id on disk.
 * If the retain count hits zero, the id is forgotten forever.
 */
- (BOOL)releaseLocalIdOnDisk:(NSString *)localId error:(NSError **)error {
    @synchronized (_lock) {
        PFObjectLocalIdStoreMapEntry *entry = [self getMapEntry:localId error:error];
        if (!entry) {
            return NO;
        }
        if (--entry.referenceCount > 0) {
            return [self putMapEntry:entry forLocalId:localId error:error];
        } else {
            return [self removeMapEntry:localId error:error];
        }
    }
}

/**
 * Sets the objectId associated with a given local id.
 */
- (BOOL)setObjectId:(NSString *)objectId forLocalId:(NSString *)localId error:(NSError **)error {
    @synchronized (_lock) {
        PFObjectLocalIdStoreMapEntry *entry = [self getMapEntry:localId error:error];
        if (!entry) {
            return NO;
        }
        if (entry.referenceCount > 0) {
            entry.objectId = objectId;
            if (![self putMapEntry:entry forLocalId:localId error:error]) {
                return NO;
            }
        }
        _inMemoryCache[localId] = objectId;
        return YES;
    }
}

/**
 * Returns the objectId associated with a given local id.
 * Returns nil if no objectId is yet known for the lcoal id.
 */
- (NSString *)objectIdForLocalId:(NSString *)localId {
    @synchronized (_lock) {
        NSString *objectId = _inMemoryCache[localId];
        if (objectId) {
            return objectId;
        }

        PFObjectLocalIdStoreMapEntry *entry = [self getMapEntry:localId error:nil];
        return entry.objectId;
    }
}

/**
 * Removes all local ids from the disk and memory caches.
 */
- (BOOL)clear {
    @synchronized (_lock) {
        [self clearInMemoryCache];

        BOOL empty = ([[NSFileManager defaultManager] enumeratorAtPath:_diskPath].allObjects.count == 0);

        [[NSFileManager defaultManager] removeItemAtPath:_diskPath error:nil];

        [[NSFileManager defaultManager] createDirectoryAtPath:_diskPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        return !empty;
    }
}

/**
 * Removes all local ids from the memory cache.
 */
- (void)clearInMemoryCache {
    @synchronized (_lock) {
        [_inMemoryCache removeAllObjects];
    }
}

@end
