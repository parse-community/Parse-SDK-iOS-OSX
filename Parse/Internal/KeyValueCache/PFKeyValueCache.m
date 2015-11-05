/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFKeyValueCache_Private.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFConstants.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFLogging.h"

static const NSUInteger PFKeyValueCacheDefaultDiskCacheSize = 10 << 20;
static const NSUInteger PFKeyValueCacheDefaultDiskCacheRecords = 1000;
static const NSUInteger PFKeyValueCacheDefaultMemoryCacheRecordSize = 1 << 20;
static const NSTimeInterval PFKeyValueCacheDiskCacheTimeResolution = 1; // HFS+ stores only second level accuracy.

static NSString *const PFKeyValueCacheDiskCachePathKey = @"path";

@interface PFKeyValueCacheEntry ()

// We need to generate a setter that's atomic to safely clear the value.
@property (nullable, atomic, readwrite, copy) NSString *value;

@end

@implementation PFKeyValueCacheEntry

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithValue:(NSString *)value {
    return [self initWithValue:value creationTime:[NSDate date]];
}

- (instancetype)initWithValue:(NSString *)value creationTime:(NSDate *)creationTime {
    self = [super init];
    if (!self) return nil;

    _value = [value copy];
    _creationTime = creationTime;

    return self;
}

+ (instancetype)cacheEntryWithValue:(NSString *)value {
    return [[self alloc] initWithValue:value];
}

+ (instancetype)cacheEntryWithValue:(NSString *)value creationTime:(NSDate *)creationTime {
    return [[self alloc] initWithValue:value creationTime:creationTime];
}

@end

@implementation PFKeyValueCache {
    NSURL *_cacheDirectoryURL;
    dispatch_queue_t _diskCacheQueue;

    NSDate *_lastDiskCacheModDate;
    NSUInteger _lastDiskCacheSize;
    NSMutableArray *_lastDiskCacheAttributes;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCacheDirectoryPath:(NSString *)path {
    return [self initWithCacheDirectoryURL:[NSURL fileURLWithPath:path]
                               fileManager:[NSFileManager defaultManager]
                               memoryCache:[[NSCache alloc] init]];
}

- (instancetype)initWithCacheDirectoryURL:(NSURL *)url
                              fileManager:(NSFileManager *)fileManager
                              memoryCache:(NSCache *)cache {
    self = [super init];
    if (!self) return nil;

    _cacheDirectoryURL = url;
    _fileManager = fileManager;
    _memoryCache = cache;

    _diskCacheQueue = dispatch_queue_create("com.parse.keyvaluecache.disk", DISPATCH_QUEUE_SERIAL);

    _maxDiskCacheBytes = PFKeyValueCacheDefaultDiskCacheSize;
    _maxDiskCacheRecords = PFKeyValueCacheDefaultDiskCacheRecords;
    _maxMemoryCacheBytesPerRecord = PFKeyValueCacheDefaultMemoryCacheRecordSize;

    return self;
}

///--------------------------------------
#pragma mark - Property Accessors
///--------------------------------------

- (NSString *)cacheDirectoryPath {
    [_fileManager createDirectoryAtURL:_cacheDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
    return _cacheDirectoryURL.path;
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key {
    [self setObject:object forKey:key];
}

- (void)setObject:(NSString *)value forKey:(NSString *)key {
    NSUInteger keyBytes = [key maximumLengthOfBytesUsingEncoding:[key fastestEncoding]];
    NSUInteger valueBytes = [value maximumLengthOfBytesUsingEncoding:[value fastestEncoding]];

    if ((keyBytes + valueBytes) < self.maxMemoryCacheBytesPerRecord) {
        [self.memoryCache setObject:[PFKeyValueCacheEntry cacheEntryWithValue:value] forKey:key];
    } else {
        [self.memoryCache removeObjectForKey:key];
    }

    dispatch_async(_diskCacheQueue, ^{
        [self _createDiskCacheEntry:value atURL:[self _cacheURLForKey:key]];
        [self _compactDiskCache];
    });
}

- (NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)maxAge {
    NSURL *cacheURL = [self _cacheURLForKey:key];
    PFKeyValueCacheEntry *cacheEntry = [self.memoryCache objectForKey:key];

    if (cacheEntry) {
        if ([[NSDate date] timeIntervalSinceDate:cacheEntry.creationTime] > maxAge) {
            // We know the cache to be too old in both copies.
            // Save space, remove this key from disk, and it's value from the memory cache.
            [self removeObjectForKey:key];
            return nil;
        }

        dispatch_async(_diskCacheQueue, ^{
            [self _updateModificationDateAtURL:cacheURL];
        });

        return cacheEntry.value;
    }

    // Wait for all outstanding disk operations before continuing, as another thread could be in the process of
    // Writing a value to disk right now.
    __block NSString *value = nil;
    dispatch_sync(_diskCacheQueue, ^{
        NSDate *modificationDate = [self _modificationDateOfCacheEntryAtURL:cacheURL];
        if ([[NSDate date] timeIntervalSinceDate:modificationDate] > maxAge) {
            [self removeObjectForKey:key];
            return;
        }

        // Cache misses here (e.g. creationDate and value are both nil) should still be put into the memory cache.
        value = [self _diskCacheEntryForURL:cacheURL];
        [self.memoryCache setObject:[PFKeyValueCacheEntry cacheEntryWithValue:value creationTime:modificationDate]
                             forKey:key];
    });

    return value;
}

- (void)removeObjectForKey:(NSString *)key {
    [self.memoryCache removeObjectForKey:key];

    dispatch_async(_diskCacheQueue, ^{
        [self.fileManager removeItemAtURL:[self _cacheURLForKey:key] error:NULL];
    });
}

- (void)removeAllObjects {
    [self.memoryCache removeAllObjects];

    dispatch_sync(_diskCacheQueue, ^{
        // Directory will be automatically recreated the next time 'cacheDir' is accessed.
        [self.fileManager removeItemAtURL:_cacheDirectoryURL error:NULL];
    });
}

- (void)waitForOutstandingOperations {
    dispatch_sync(_diskCacheQueue, ^{
        // Wait, do nothing
    });
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (NSURL *)_cacheURLForKey:(NSString *)key {
    return [_cacheDirectoryURL URLByAppendingPathComponent:key];
}

- (void)_updateModificationDateAtURL:(NSURL *)url {
    [self.fileManager setAttributes:@{ NSFileModificationDate: [NSDate date] } ofItemAtPath:url.path error:NULL];
}

- (NSDate *)_modificationDateOfCacheEntryAtURL:(NSURL *)url {
    return [self.fileManager attributesOfItemAtPath:url.path error:NULL][NSFileModificationDate];
}

///--------------------------------------
#pragma mark - Disk Cache
///--------------------------------------

- (NSString *)_diskCacheEntryForURL:(NSURL *)url {
    NSData *bytes = [self.fileManager contentsAtPath:[url path]];
    if (!bytes) {
        return nil;
    }

    [self _updateModificationDateAtURL:url];
    return [[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
}

- (void)_createDiskCacheEntry:(NSString *)value atURL:(NSURL *)url {
    NSString *path = [url path];
    NSData *bytes = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDate *creationDate = [NSDate date];

    BOOL isDirty = [self _isDiskCacheDirty];

    [_fileManager createDirectoryAtURL:_cacheDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
    [self.fileManager createFileAtPath:path
                              contents:bytes
                            attributes:@{ NSFileCreationDate: creationDate, NSFileModificationDate: creationDate }];

    if (!isDirty) {
        _lastDiskCacheModDate = creationDate;
        _lastDiskCacheSize += bytes.length;

        [self _addToDiskCacheDictionary:path
                       modificationDate:creationDate
                                   size:bytes.length];
    } else {
        [self _invalidateDiskCache];
    }
}

- (BOOL)_isDiskCacheDirty {
    if (!_lastDiskCacheModDate) {
        return YES;
    }

    NSDate *modificationDate = [self _modificationDateOfCacheEntryAtURL:_cacheDirectoryURL];
    NSTimeInterval knownInterval = [_lastDiskCacheModDate timeIntervalSinceReferenceDate];
    NSTimeInterval actualInterval = [modificationDate timeIntervalSinceReferenceDate];

    // NOTE: Most file systems (HFS) can only store up to 1 second of precision, whereas NSDate is super high resolution
    // Yes, this is actually really bad to have hard coded, as this does give some window where we can get unwanted
    // entries in the cache. However, that chance of another process touching this directory is greatly outweighed by
    // the performance gained by using this technique. Plus, in the case of concurrent modification, we will never over-
    // agressively remove something from the cache, we just might go a little bit over our limit.
    return (actualInterval - knownInterval) >= PFKeyValueCacheDiskCacheTimeResolution;
}

- (void)_invalidateDiskCache {
    _lastDiskCacheModDate = nil;
    _lastDiskCacheSize = 0;
    _lastDiskCacheAttributes = nil;
}

- (void)_recreateDiskCache {
    NSDictionary *cacheDirectoryAttributes = [self.fileManager attributesOfItemAtPath:_cacheDirectoryURL.path error:NULL];

    _lastDiskCacheModDate = cacheDirectoryAttributes[NSFileModificationDate];
    _lastDiskCacheSize = 0;
    _lastDiskCacheAttributes = [[NSMutableArray alloc] init];

    NSDirectoryEnumerator *enumerator = [self.fileManager enumeratorAtPath:[_cacheDirectoryURL path]];
    NSString *path = nil;

    while ((path = [enumerator nextObject]) != nil) {
        [enumerator skipDescendants];

        NSDictionary *attributes = enumerator.fileAttributes;
        NSUInteger size = [attributes[NSFileSize] unsignedIntegerValue];

        _lastDiskCacheSize += size;

        // NOTE: Do not use -copy here, as fileAttributes are lazily-loaded, we would run into issues with a lot of
        // syscalls all at once here.
        [self _addToDiskCacheDictionary:path
                       modificationDate:attributes[NSFileModificationDate]
                                   size:size];
    }
}

- (void)_addToDiskCacheDictionary:(NSString *)path modificationDate:(NSDate *)modificationDate size:(NSUInteger)size {
    NSDictionary *entry = @{
        PFKeyValueCacheDiskCachePathKey: path,
        NSFileModificationDate: modificationDate,
        NSFileSize: @(size)
    };

    NSInteger insertionIndex = [_lastDiskCacheAttributes indexOfObject:entry
                                                         inSortedRange:NSMakeRange(0, _lastDiskCacheAttributes.count)
                                                               options:NSBinarySearchingInsertionIndex
                                                       usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                           return [obj1[NSFileModificationDate] compare:obj2[NSFileModificationDate]];
                                                        }];

    [_lastDiskCacheAttributes insertObject:entry atIndex:insertionIndex];
}

- (void)_compactDiskCache {
    if ([self _isDiskCacheDirty]) {
        [self _recreateDiskCache];
    }

    while (_lastDiskCacheAttributes.count > _maxDiskCacheRecords || _lastDiskCacheSize > _maxDiskCacheBytes) {
        NSDictionary *attributes = [_lastDiskCacheAttributes firstObject];
        NSString *toRemove = attributes[PFKeyValueCacheDiskCachePathKey];
        NSNumber *fileSize = attributes[NSFileSize];

        [self.fileManager removeItemAtURL:[self _cacheURLForKey:toRemove] error:NULL];
        _lastDiskCacheSize -= [fileSize unsignedIntegerValue];

        [_lastDiskCacheAttributes removeObjectAtIndex:0];
    }
}

@end
