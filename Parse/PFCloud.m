/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloud.h"

#import "BFTask+Private.h"
#import "PFCloudCodeController.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFCloud

///--------------------------------------
#pragma mark - Public
///--------------------------------------

+ (BFTask *)callFunctionInBackground:(NSString *)functionName withParameters:(NSDictionary *)parameters {
    return [[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFCloudCodeController *controller = [Parse _currentManager].coreManager.cloudCodeController;
        return [controller callCloudCodeFunctionAsync:functionName
                                       withParameters:parameters
                                         sessionToken:sessionToken];
    }];
}

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
                           block:(PFIdResultBlock)block {
    [[self callFunctionInBackground:function withParameters:parameters] thenCallBackOnMainThreadAsync:block];
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFCloud (Synchronous)

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters {
    return [self callFunction:function withParameters:parameters error:nil];
}

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters error:(NSError **)error {
    return [[self callFunctionInBackground:function withParameters:parameters] waitForResult:error];
}

@end

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

@implementation PFCloud (Deprecated)

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(nullable NSDictionary *)parameters
                          target:(nullable id)target
                        selector:(nullable SEL)selector {
    [self callFunctionInBackground:function withParameters:parameters block:^(id results, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:results object:error];
    }];
}

@end
