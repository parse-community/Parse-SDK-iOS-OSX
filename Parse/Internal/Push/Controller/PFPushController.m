/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPushController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandRunning.h"
#import "PFMacros.h"
#import "PFRESTPushCommand.h"

@implementation PFPushController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner {
    self = [super init];
    if (!self) return nil;

    _commandRunner = commandRunner;

    return self;
}

+ (instancetype)controllerWithCommandRunner:(id<PFCommandRunning>)commandRunner {
    return [[self alloc] initWithCommandRunner:commandRunner];
}

///--------------------------------------
#pragma mark - Sending Push
///--------------------------------------

- (BFTask *)sendPushNotificationAsyncWithState:(PFPushState *)state
                                  sessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        PFRESTCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:sessionToken];
        return [self.commandRunner runCommandAsync:command withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return @(task.result != nil);
    }];
}

@end
