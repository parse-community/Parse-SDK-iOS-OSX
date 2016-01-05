/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectFilePersistenceController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFJSONSerialization.h"
#import "PFMacros.h"
#import "PFObjectFileCoder.h"
#import "PFObjectPrivate.h"
#import "PFPersistenceController.h"

@implementation PFObjectFilePersistenceController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFPersistenceControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Objects
///--------------------------------------

- (BFTask<PFObject *> *)loadPersistentObjectAsyncForKey:(NSString *)key {
    return [[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        id<PFPersistenceGroup> group = task.result;
        __block PFObject *object = nil;
        return [[[[[group beginLockedContentAccessAsyncToDataForKey:key] continueWithSuccessBlock:^id(BFTask *_) {
            return [group getDataAsyncForKey:key];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            NSData *data = task.result;
            if (data) {
                object = [PFObjectFileCoder objectFromData:data usingDecoder:[PFDecoder objectDecoder]];
            }
            return nil;
        }] continueWithBlock:^id(BFTask *task) {
            return [group endLockedContentAccessAsyncToDataForKey:key];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            // Finalize everything with object pointer.
            return object;
        }];
    }];
}

- (BFTask *)persistObjectAsync:(PFObject *)object forKey:(NSString *)key {
    return [[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        id<PFPersistenceGroup> group = task.result;
        return [[[group beginLockedContentAccessAsyncToDataForKey:key] continueWithSuccessBlock:^id(BFTask *_) {
            NSData *data = [PFObjectFileCoder dataFromObject:object usingEncoder:[PFPointerObjectEncoder objectEncoder]];
            return [group setDataAsync:data forKey:key];
        }] continueWithBlock:^id(BFTask *task) {
            return [group endLockedContentAccessAsyncToDataForKey:key];
        }];
    }];
}

- (BFTask *)removePersistentObjectAsyncForKey:(NSString *)key {
    return [[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        id<PFPersistenceGroup> group = task.result;
        return [[[group beginLockedContentAccessAsyncToDataForKey:key] continueWithSuccessBlock:^id(BFTask *_) {
            return [group removeDataAsyncForKey:key];
        }] continueWithBlock:^id(BFTask *_) {
            return [group endLockedContentAccessAsyncToDataForKey:key];
        }];
    }];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)_getPersistenceGroupAsync {
    return [self.dataSource.persistenceController getPersistenceGroupAsync];
}

@end
