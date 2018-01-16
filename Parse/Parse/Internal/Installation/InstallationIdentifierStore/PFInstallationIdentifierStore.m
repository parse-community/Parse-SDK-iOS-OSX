/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallationIdentifierStore.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "Parse_Private.h"
#import "PFAsyncTaskQueue.h"
#import "PFPersistenceController.h"

static NSString *const PFInstallationIdentifierFileName = @"installationId";

@interface PFInstallationIdentifierStore () {
    PFAsyncTaskQueue *_taskQueue;
}

@property (nonatomic, copy) NSString *installationIdentifier;

@end

@implementation PFInstallationIdentifierStore

@synthesize installationIdentifier = _installationIdentifier;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _taskQueue = [[PFAsyncTaskQueue alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BFTask<NSString *> *)getInstallationIdentifierAsync {
    return [_taskQueue enqueue:^id(BFTask *_) {
        if (!self.installationIdentifier) {
            return [self _loadInstallationIdentifierAsync];
        }
        return self.installationIdentifier;
    }];
}

- (BFTask *)clearInstallationIdentifierAsync {
    return [_taskQueue enqueue:^id(BFTask *_) {
        self.installationIdentifier = nil;
        return [[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
            id<PFPersistenceGroup> group = task.result;
            return [[[group beginLockedContentAccessAsyncToDataForKey:PFInstallationIdentifierFileName] continueWithSuccessBlock:^id(BFTask *t) {
                return [group removeDataAsyncForKey:PFInstallationIdentifierFileName];
            }] continueWithBlock:^id(BFTask *t) {
                return [group endLockedContentAccessAsyncToDataForKey:PFInstallationIdentifierFileName];
            }];
        }];
    }];
}

- (BFTask *)_clearCachedInstallationIdentifierAsync {
    return [_taskQueue enqueue:^id(BFTask *_) {
        self.installationIdentifier = nil;
        return nil;
    }];
}

///--------------------------------------
#pragma mark - Disk Operations
///--------------------------------------

- (BFTask<NSString *> *)_loadInstallationIdentifierAsync {
    return (BFTask<NSString *> *)[[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        id<PFPersistenceGroup> group = task.result;
        return [[[[[group beginLockedContentAccessAsyncToDataForKey:PFInstallationIdentifierFileName] continueWithSuccessBlock:^id(BFTask *_) {
            return [group getDataAsyncForKey:PFInstallationIdentifierFileName];
        }] continueWithSuccessBlock:^id(BFTask *t) {
            NSData *data = t.result;
            NSString *installationId = nil;
            if (data) {
                installationId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (installationId) {
                    self.installationIdentifier = installationId;
                    return installationId;
                }
            }
            installationId = [NSUUID UUID].UUIDString.lowercaseString;
            return [[group setDataAsync:[installationId dataUsingEncoding:NSUTF8StringEncoding]
                                 forKey:PFInstallationIdentifierFileName] continueWithSuccessResult:installationId];
        }] continueWithBlock:^id(BFTask<NSString *> *t) {
            [group endLockedContentAccessAsyncToDataForKey:PFInstallationIdentifierFileName];
            return t;
        }] continueWithSuccessBlock:^id _Nullable(BFTask<NSString *> * _Nonnull t) {
            self.installationIdentifier = t.result;
            return self.installationIdentifier;
        }];
    }];
}

- (BFTask<id<PFPersistenceGroup>> *)_getPersistenceGroupAsync {
    return [self.dataSource.persistenceController getPersistenceGroupAsync];
}

@end
