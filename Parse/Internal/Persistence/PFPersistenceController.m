/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPersistenceController.h"

#import "BFTask+Private.h"
#import "PFAsyncTaskQueue.h"

#import "PFFilePersistenceGroup.h"
#import "PFUserDefaultsPersistenceGroup.h"
#import "PFFileManager.h"

static NSString *const PFFilePersistenceParseDirectoryName = @"Parse";
static NSString *const PFUserDefaultsPersistenceParseKey = @"com.parse";

@interface PFPersistenceController () {
    id<PFPersistenceGroup> _persistenceGroup;
    PFAsyncTaskQueue *_dataQueue;
    PFPersistenceGroupValidationHandler _groupValidationHandler;
}

@end

@implementation PFPersistenceController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithApplicationIdentifier:(nonnull NSString *)applicationIdentifier
                   applicationGroupIdentifier:(nullable NSString *)applicationGroupIdentifier
                       groupValidationHandler:(nonnull PFPersistenceGroupValidationHandler)handler{
    self = [super init];
    if (!self) return nil;

    _applicationIdentifier = [applicationIdentifier copy];
    _applicationGroupIdentifier = [applicationGroupIdentifier copy];
    _groupValidationHandler = [handler copy];

    _dataQueue = [[PFAsyncTaskQueue alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - Persistence
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)getPersistenceGroupAsync {
    return [_dataQueue enqueue:^id(BFTask *task) {
        if (_persistenceGroup) {
            return _persistenceGroup;
        }
        return [self _loadPersistenceGroup];
    }];
}

///--------------------------------------
#pragma mark - Load
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)_loadPersistenceGroup {
    return [[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
#if TARGET_OS_TV
        return [self _createUserDefaultsPersistenceGroup];
#else
        return [self _createFilePersistenceGroup];
#endif
    }] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        id<PFPersistenceGroup> group = task.result;
        return [_groupValidationHandler(group) continueWithSuccessBlock:^id(BFTask *_) {
            _persistenceGroup = group;
            return _persistenceGroup;
        }];
    }];
}

///--------------------------------------
#pragma mark - File Group
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)_createFilePersistenceGroup {
    return [[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSString *storagePath = [self _filePersistenceGroupStoragePath];
        return [[PFFileManager createDirectoryIfNeededAsyncAtPath:storagePath] continueWithSuccessBlock:^id(BFTask *task) {
            return storagePath;
        }];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSString *storagePath = task.result;
        PFFilePersistenceGroupOptions options = 0;
        if (_applicationGroupIdentifier) {
            options |= PFFilePersistenceGroupOptionUseFileLocks;
        }
        return [[PFFilePersistenceGroup alloc] initWithStorageDirectoryPath:storagePath options:options];
    }];
}

- (NSString *)_filePersistenceGroupStoragePath {
    NSString *directoryPath = nil;
#if PF_TARGET_OS_OSX
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    directoryPath = [paths firstObject];
    directoryPath = [directoryPath stringByAppendingPathComponent:PFFilePersistenceParseDirectoryName];
    directoryPath = [directoryPath stringByAppendingPathComponent:self.applicationIdentifier];
#else
    if (self.applicationGroupIdentifier) {
        NSURL *containerPath = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.applicationGroupIdentifier];
        directoryPath = [containerPath.path stringByAppendingPathComponent:PFFilePersistenceParseDirectoryName];
        directoryPath = [directoryPath stringByAppendingPathComponent:self.applicationIdentifier];
    } else {
        NSString *library = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        NSString *privateDocuments = [library stringByAppendingPathComponent:@"Private Documents"];
        directoryPath = [privateDocuments stringByAppendingPathComponent:PFFilePersistenceParseDirectoryName];
    }
#endif
    return directoryPath;
}

///--------------------------------------
#pragma mark - UserDefaults Group
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)_createUserDefaultsPersistenceGroup {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        return [[PFUserDefaultsPersistenceGroup alloc] initWithKey:PFUserDefaultsPersistenceParseKey];
    }];
}

@end
