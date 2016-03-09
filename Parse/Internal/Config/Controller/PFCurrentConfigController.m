/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCurrentConfigController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFConfig_Private.h"
#import "PFDecoder.h"
#import "PFPersistenceController.h"
#import "PFJSONSerialization.h"
#import "PFAsyncTaskQueue.h"

static NSString *const PFConfigCurrentConfigFileName_ = @"config";

@interface PFCurrentConfigController () {
    PFAsyncTaskQueue *_dataTaskQueue;
    PFConfig *_currentConfig;
}

@property (nonatomic, copy, readonly) NSString *configFilePath;

@end

@implementation PFCurrentConfigController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataTaskQueue = [[PFAsyncTaskQueue alloc] init];

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFPersistenceControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BFTask *)getCurrentConfigAsync {
    return [_dataTaskQueue enqueue:^id(BFTask *_) {
        if (!_currentConfig) {
            return [[self _loadConfigAsync] continueWithSuccessBlock:^id(BFTask<PFConfig *> *task) {
                _currentConfig = task.result;
                return _currentConfig;
            }];
        }
        return _currentConfig;
    }];
}

- (BFTask *)setCurrentConfigAsync:(PFConfig *)config {
    @weakify(self);
    return [_dataTaskQueue enqueue:^id(BFTask *_) {
        @strongify(self);
        _currentConfig = config;

        NSDictionary *configParameters = @{ PFConfigParametersRESTKey : (config.parametersDictionary ?: @{}) };
        id encodedObject = [[PFPointerObjectEncoder objectEncoder] encodeObject:configParameters];
        NSData *jsonData = [PFJSONSerialization dataFromJSONObject:encodedObject];
        return [[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
            return [task.result setDataAsync:jsonData forKey:PFConfigCurrentConfigFileName_];
        }];
    }];
}

- (BFTask *)clearCurrentConfigAsync {
    @weakify(self);
    return [_dataTaskQueue enqueue:^id(BFTask *_) {
        @strongify(self);
        _currentConfig = nil;
        return [[self.dataSource.persistenceController getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
            return [task.result removeDataAsyncForKey:PFConfigCurrentConfigFileName_];
        }];
    }];
}

- (BFTask *)clearMemoryCachedCurrentConfigAsync {
    return [_dataTaskQueue enqueue:^id(BFTask *_) {
        _currentConfig = nil;
        return nil;
    }];
}

///--------------------------------------
#pragma mark - Data
///--------------------------------------

- (BFTask<PFConfig *> *)_loadConfigAsync {
    return [[[self _getPersistenceGroupAsync] continueWithSuccessBlock:^id(BFTask<id<PFPersistenceGroup>> *task) {
        return [task.result getDataAsyncForKey:PFConfigCurrentConfigFileName_];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        if (task.result) {
            NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:task.result];
            if (dictionary) {
                NSDictionary *decodedDictionary = [[PFDecoder objectDecoder] decodeObject:dictionary];
                return [[PFConfig alloc] initWithFetchedConfig:decodedDictionary];
            }
        }
        return [[PFConfig alloc] init];
    }];
}

///--------------------------------------
#pragma mark - Convenience
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)_getPersistenceGroupAsync {
    return [self.dataSource.persistenceController getPersistenceGroupAsync];
}

@end
