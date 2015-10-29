/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFConfigController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFConfig_Private.h"
#import "PFCurrentConfigController.h"
#import "PFDecoder.h"
#import "PFRESTConfigCommand.h"

@interface PFConfigController () {
    dispatch_queue_t _dataAccessQueue;
    dispatch_queue_t _networkQueue;
    BFExecutor *_networkExecutor;
}

@end

@implementation PFConfigController

@synthesize currentConfigController = _currentConfigController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider, PFCommandRunnerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _dataAccessQueue = dispatch_queue_create("com.parse.config.access", DISPATCH_QUEUE_SERIAL);

    _networkQueue = dispatch_queue_create("com.parse.config.network", DISPATCH_QUEUE_SERIAL);
    _networkExecutor = [BFExecutor executorWithDispatchQueue:_networkQueue];

    return self;
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchConfigAsyncWithSessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [BFTask taskFromExecutor:_networkExecutor withBlock:^id {
        @strongify(self);
        PFRESTCommand *command = [PFRESTConfigCommand configFetchCommandWithSessionToken:sessionToken];
        return [[[self.dataSource.commandRunner runCommandAsync:command
                                                    withOptions:PFCommandRunningOptionRetryIfFailed]
                 continueWithSuccessBlock:^id(BFTask *task) {
                     PFCommandResult *result = task.result;
                     NSDictionary *fetchedConfig = [[PFDecoder objectDecoder] decodeObject:result.result];
                     return [[PFConfig alloc] initWithFetchedConfig:fetchedConfig];
                 }] continueWithSuccessBlock:^id(BFTask *task) {
                     // Roll-forward the config.
                     return [[self.currentConfigController setCurrentConfigAsync:task.result] continueWithResult:task.result];
                 }];
    }];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFCurrentConfigController *)currentConfigController {
    __block PFCurrentConfigController *controller = nil;
    dispatch_sync(_dataAccessQueue, ^{
        if (!_currentConfigController) {
            _currentConfigController = [[PFCurrentConfigController alloc] initWithDataSource:self.dataSource];
        }
        controller = _currentConfigController;
    });
    return controller;
}

@end
