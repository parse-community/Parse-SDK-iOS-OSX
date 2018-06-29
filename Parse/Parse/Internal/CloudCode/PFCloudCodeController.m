/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloudCodeController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFInternalUtils.h"
#import "PFRESTCloudCommand.h"

@implementation PFCloudCodeController

///--------------------------------------
#pragma mark - Init
///--------------------------------------s

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
#pragma mark - Cloud Functions
///--------------------------------------

- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                          sessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSError *error;
        NSDictionary *encodedParameters = [[PFNoObjectEncoder objectEncoder] encodeObject:parameters error:&error];
        PFPreconditionReturnFailedTask(encodedParameters, error);
        PFRESTCloudCommand *command = [PFRESTCloudCommand commandForFunction:functionName
                                                              withParameters:encodedParameters
                                                                sessionToken:sessionToken
                                                                       error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.dataSource.commandRunner runCommandAsync:command withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return ((PFCommandResult *)(task.result)).result[@"result"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return [[PFDecoder objectDecoder] decodeObject:task.result];
    }];
}

@end
