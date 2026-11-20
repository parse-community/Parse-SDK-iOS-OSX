/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloudCodeController.h"

#if __has_include(<Bolts/BFCancellationToken.h>)
#import <Bolts/BFCancellationToken.h>
#else
#import "BFCancellationToken.h"
#endif

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
    return [self callCloudCodeFunctionAsync:functionName
                             withParameters:parameters
                               sessionToken:sessionToken
                          cancellationToken:nil];
}

- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                          sessionToken:(NSString *)sessionToken
                     cancellationToken:(BFCancellationToken *)cancellationToken {
    @weakify(self);
    return [[[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }
        NSError *error;
        NSDictionary *encodedParameters = [[PFNoObjectEncoder objectEncoder] encodeObject:parameters error:&error];
        PFPreconditionReturnFailedTask(encodedParameters, error);
        PFRESTCloudCommand *command = [PFRESTCloudCommand commandForFunction:functionName
                                                              withParameters:encodedParameters
                                                                sessionToken:sessionToken
                                                                       error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.dataSource.commandRunner runCommandAsync:command
                                                  withOptions:PFCommandRunningOptionRetryIfFailed
                                            cancellationToken:cancellationToken];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return ((PFCommandResult *)(task.result)).result[@"result"];
    } cancellationToken:cancellationToken] continueWithSuccessBlock:^id(BFTask *task) {
        return [[PFDecoder objectDecoder] decodeObject:task.result];
    } cancellationToken:cancellationToken];
}

@end
