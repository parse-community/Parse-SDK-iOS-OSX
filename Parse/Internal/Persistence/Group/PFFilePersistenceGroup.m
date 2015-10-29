/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFilePersistenceGroup.h"

#import "BFTask+Private.h"
#import "PFMultiProcessFileLockController.h"
#import "PFFileManager.h"

@implementation PFFilePersistenceGroup

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithStorageDirectoryPath:(NSString *)path
                                     options:(PFFilePersistenceGroupOptions)options {
    self = [super init];
    if (!self) return nil;

    _storageDirectoryPath = path;
    _options = options;

    return self;
}

///--------------------------------------
#pragma mark - PFPersistenceGroup
///--------------------------------------

- (BFTask PF_GENERIC(NSData *)*)getDataAsyncForKey:(NSString *)key {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSString *path = [self _filePathForItemForKey:key];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return nil;
        }

        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:path
                                              options:NSDataReadingMappedIfSafe
                                                error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return data;
    }];
}

- (BFTask *)setDataAsync:(NSData *)data forKey:(NSString *)key {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSString *path = [self _filePathForItemForKey:key];
        NSError *error = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&error];

        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

- (BFTask *)removeDataAsyncForKey:(NSString *)key {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSString *path = [self _filePathForItemForKey:key];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

- (BFTask *)removeAllDataAsync {
    return [PFFileManager removeDirectoryContentsAsyncAtPath:self.storageDirectoryPath];
}

- (BFTask *)beginLockedContentAccessAsyncToDataForKey:(NSString *)key {
    if ((self.options & PFFilePersistenceGroupOptionUseFileLocks) != PFFilePersistenceGroupOptionUseFileLocks) {
        return [BFTask taskWithResult:nil];
    }

    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSString *path = [self _filePathForItemForKey:key];
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:path];
        return nil;
    }];
}

- (BFTask *)endLockedContentAccessAsyncToDataForKey:(NSString *)key {
    if ((self.options & PFFilePersistenceGroupOptionUseFileLocks) != PFFilePersistenceGroupOptionUseFileLocks) {
        return [BFTask taskWithResult:nil];
    }

    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSString *path = [self _filePathForItemForKey:key];
    [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];
        return nil;
    }];
}

///--------------------------------------
#pragma mark - Paths
///--------------------------------------

- (NSString *)_filePathForItemForKey:(NSString *)key {
    return [self.storageDirectoryPath stringByAppendingPathComponent:key];
}

@end
