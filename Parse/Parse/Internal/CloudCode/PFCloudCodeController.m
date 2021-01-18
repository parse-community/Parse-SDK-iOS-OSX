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

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Cloud Functions
///--------------------------------------

- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                           cachePolicy:(PFCachePolicty)cachePolicy
                           maxCacheAge:(NSTimeInterval)maxCacheAge
                          sessionToken:(NSString *)sessionToken{
   
    NSString *cacheKey = [self cacheKeyForFunction:functionName parameters:parameters sessionToken:sessionToken];
    
    switch (cachePolicy) {
        case kPFCachePolicyIgnoreCache:
        {
            return [self callCloudCodeFunctionAsync:functionName withParameters:parameters sessionToken:sessionToken];
        }
            break;
        case kPFCachePolicyNetworkOnly:
        {
            return [[self callCloudCodeFunctionAsync:functionName withParameters:parameters sessionToken:sessionToken] continueWithSuccessBlock:^id(BFTask *task) {
                return [self _saveCommandResultAsync:task.result forCommandCacheKey:cacheKey];
            }];
        }
            break;
        case kPFCachePolicyCacheOnly: {
            return [self taskWithCacheKey: cacheKey];
        }
            break;
        case kPFCachePolicyNetworkElseCache: {
            // Don't retry for network-else-cache, because it just slows things down.
            BFTask *networkTask = [self callCloudCodeFunctionAsync:functionName withParameters:parameters sessionToken:sessionToken];
            @weakify(self);
            return [networkTask continueWithBlock:^id(BFTask *task) {
                @strongify(self);
                if (task.cancelled) {
                    return task;
                } else if (task.faulted) {
                    return [self taskWithCacheKey: cacheKey];
                }
                return [self _saveCommandResultAsync:task.result forCommandCacheKey:cacheKey];
            }];
        }
            break;
        case kPFCachePolicyCacheElseNetwork:
        {
            BFTask *cacheTask = [self taskWithCacheKey: cacheKey];
            @weakify(self);
            return [cacheTask continueWithBlock:^id(BFTask *task) {
                @strongify(self);
                if (task.error) {
                    return [self callCloudCodeFunctionAsync:functionName withParameters:parameters sessionToken:sessionToken];
                }
                return task;
            }];
        }
            break;
        case kPFCachePolicyCacheThenNetwork: {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidQuery
                                                     message:@"Cache then network is not supported directly in PFCloudCodeController."];
            return [BFTask taskWithError:error];
        }
            break;
        default: {
            NSString *message = [NSString stringWithFormat:@"Unrecognized cache policy: %d", queryState.cachePolicy];
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidQuery message:message];
            return [BFTask taskWithError:error];
        }
            break;
    }
    return nil;
}

- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                        sessionToken:(NSString *)sessionToken{
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
        
        PFCommandRunningOptions options = 0;
        if (cachePolicy != kPFCachePolicyNetworkElseCache) {
            options = PFCommandRunningOptionRetryIfFailed;
        }
        return [self.dataSource.commandRunner runCommandAsync:command withOptions:options];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return ((PFCommandResult *)(task.result)).result[@"result"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        if (cachePolicy == kPFCachePolicyNetworkOnly ||
            cachePolicy == kPFCachePolicyNetworkElseCache ||
            cachePolicy == kPFCachePolicyCacheElseNetwork) {
            BFTask *newTask = [self _saveCommandResultAsync:task.result forCommandCacheKey:cacheKey];
            return [[PFDecoder objectDecoder] decodeObject:newTask.result];
        }
        
        return [[PFDecoder objectDecoder] decodeObject:task.result];
    }];
}

///--------------------------------------
#pragma mark - Caching
///--------------------------------------

- (nullable NSString *)cacheKeyForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken {
    NSDictionary *encodedParameters = [[PFNoObjectEncoder objectEncoder] encodeObject:parameters error:nil];
    return [PFRESTCloudCommand commandForFunction:functionName
                                   withParameters:encodedParameters
                                     sessionToken:sessionToken
                                            error:nil].cacheKey;
}

- (BOOL)hasCachedResultForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken {
    NSString *cacheKey = [self cacheKeyForFunction:functionName parameters:parameters sessionToken:sessionToken];
    return ([self.dataSource.keyValueCache objectForKey:cacheKey maxAge:60] != nil);
}

- (void)clearCachedResultForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken {
    NSString *cacheKey = [self cacheKeyForFunction:functionName parameters:parameters sessionToken:sessionToken];
    [self.dataSource.keyValueCache removeObjectForKey:cacheKey];
}

- (void)clearAllCachedResults {
    [self.dataSource.keyValueCache removeAllObjects];
}

- (BFTask *)taskWithCacheKey:(NSString*)cacheKey
                 maxCacheAge:(NSTimeInterval)maxCacheAge {
                               
    NSString *jsonString = [self.dataSource.keyValueCache objectForKey:cacheKey maxAge:maxCacheAge];
    if (!jsonString) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorCacheMiss
                                                 message:@"Cache miss."
                                               shouldLog:NO];
        return [BFTask taskWithError:error];
    }
    
    NSDictionary *object = [PFJSONSerialization JSONObjectFromString:jsonString];
    if (!object) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorCacheMiss
                                                 message:@"Cache contains corrupted JSON."];
        return [BFTask taskWithError:error];
    }
    
    NSDictionary *decodedObject = [[PFDecoder objectDecoder] decodeObject:object];
    
    PFCommandResult *result = [PFCommandResult commandResultWithResult:decodedObject
                                                          resultString:jsonString
                                                          httpResponse:nil];
    return [BFTask taskWithResult:result];
}

- (BFTask *)_saveCommandResultAsync:(PFCommandResult *)result forCommandCacheKey:(NSString *)cacheKey {
    NSString *resultString = result.resultString;
    if (resultString) {
        self.dataSource.keyValueCache[cacheKey] = resultString;
    }
    // Roll-forward the original result.
    return [BFTask taskWithResult:result];
}

@end
