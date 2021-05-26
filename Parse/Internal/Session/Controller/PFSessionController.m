/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSessionController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFObjectPrivate.h"
#import "PFRESTSessionCommand.h"
#import "PFSession.h"

@implementation PFSessionController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Current Session
///--------------------------------------

- (BFTask *)getCurrentSessionAsyncWithSessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        PFRESTCommand *command = [PFRESTSessionCommand getCurrentSessionCommandWithSessionToken:sessionToken];
        return [self.dataSource.commandRunner runCommandAsync:command
                                                  withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFCommandResult *result = task.result;
        NSDictionary *dictionary = result.result;
        PFSession *session = [PFSession _objectFromDictionary:dictionary
                                             defaultClassName:[PFSession parseClassName]
                                                 completeData:YES];
        return session;
    }];
}

@end
