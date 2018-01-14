/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCachedQueryController.h"

#import <Bolts/BFTask.h>

#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFDecoder.h"
#import "PFErrorUtilities.h"
#import "PFJSONSerialization.h"
#import "PFKeyValueCache.h"
#import "PFMacros.h"
#import "PFQueryState.h"
#import "PFRESTCommand.h"
#import "PFRESTQueryCommand.h"
#import "PFUser.h"

@implementation PFCachedQueryController

@dynamic commonDataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource {
    return [super initWithCommonDataSource:dataSource];
}

+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource {
    return [super controllerWithCommonDataSource:dataSource];
}

///--------------------------------------
#pragma mark - PFQueryControllerSubclass
///--------------------------------------

- (BFTask *)runNetworkCommandAsync:(PFRESTCommand *)command
             withCancellationToken:(BFCancellationToken *)cancellationToken
                     forQueryState:(PFQueryState *)queryState {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }

    switch (queryState.cachePolicy) {
        case kPFCachePolicyIgnoreCache:
        {
            return [self _runNetworkCommandAsync:command
                           withCancellationToken:cancellationToken
                                   forQueryState:queryState];
        }
            break;
        case kPFCachePolicyNetworkOnly:
        {
            return [[self _runNetworkCommandAsync:command
                            withCancellationToken:cancellationToken
                                    forQueryState:queryState] continueWithSuccessBlock:^id(BFTask *task) {
                return [self _saveCommandResultAsync:task.result forCommandCacheKey:command.cacheKey];
            } cancellationToken:cancellationToken];
        }
            break;
        case kPFCachePolicyCacheOnly: {
            return [self _runNetworkCommandAsyncFromCache:command
                                    withCancellationToken:cancellationToken
                                            forQueryState:queryState];
        }
            break;
        case kPFCachePolicyNetworkElseCache: {
            // Don't retry for network-else-cache, because it just slows things down.
            BFTask *networkTask = [self _runNetworkCommandAsync:command
                                          withCancellationToken:cancellationToken
                                                  forQueryState:queryState];
            @weakify(self);
            return [networkTask continueWithBlock:^id(BFTask *task) {
                @strongify(self);
                if (task.cancelled) {
                    return task;
                } else if (task.faulted) {
                    return [self _runNetworkCommandAsyncFromCache:command
                                            withCancellationToken:cancellationToken
                                                    forQueryState:queryState];
                }
                return [self _saveCommandResultAsync:task.result forCommandCacheKey:command.cacheKey];
            } cancellationToken:cancellationToken];
        }
            break;
        case kPFCachePolicyCacheElseNetwork:
        {
            BFTask *cacheTask = [self _runNetworkCommandAsyncFromCache:command
                                                 withCancellationToken:cancellationToken
                                                         forQueryState:queryState];
            @weakify(self);
            return [cacheTask continueWithBlock:^id(BFTask *task) {
                @strongify(self);
                if (task.error) {
                    return [self _runNetworkCommandAsync:command
                                   withCancellationToken:cancellationToken
                                           forQueryState:queryState];
                }
                return task;
            } cancellationToken:cancellationToken];
        }
            break;
        case kPFCachePolicyCacheThenNetwork: {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidQuery
                                                     message:@"Cache then network is not supported directly in PFCachedQueryController."];
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

- (BFTask *)_runNetworkCommandAsync:(PFRESTCommand *)command
              withCancellationToken:(BFCancellationToken *)cancellationToken
                      forQueryState:(PFQueryState *)queryState {
    PFCommandRunningOptions options = 0;
    // We don't want retries on NetworkElseCache, but rather instantly back-off to cache.
    if (queryState.cachePolicy != kPFCachePolicyNetworkElseCache) {
        options = PFCommandRunningOptionRetryIfFailed;
    }
    BFTask *networkTask = [self.commonDataSource.commandRunner runCommandAsync:command
                                                                   withOptions:options
                                                             cancellationToken:cancellationToken];
    return [networkTask continueWithSuccessBlock:^id(BFTask *task) {
        if (queryState.cachePolicy == kPFCachePolicyNetworkOnly ||
            queryState.cachePolicy == kPFCachePolicyNetworkElseCache ||
            queryState.cachePolicy == kPFCachePolicyCacheElseNetwork) {
            return [self _saveCommandResultAsync:task.result forCommandCacheKey:command.cacheKey];
        }
        // Roll-forward the original result.
        return task;
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Cache
///--------------------------------------

- (NSString *)cacheKeyForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
    return [PFRESTQueryCommand findCommandForQueryState:queryState withSessionToken:sessionToken].cacheKey;
}

- (BOOL)hasCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
    // TODO: (nlutsenko) Once there is caching for `count`, the results for that command should also be checked.
    // TODO: (nlutsenko) We should cache this result.

    NSString *cacheKey = [self cacheKeyForQueryState:queryState sessionToken:sessionToken];
    return ([self.commonDataSource.keyValueCache objectForKey:cacheKey maxAge:queryState.maxCacheAge] != nil);
}

- (void)clearCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
    // TODO: (nlutsenko) Once there is caching for `count`, the results for that command should also be cleared.
    NSString *cacheKey = [self cacheKeyForQueryState:queryState sessionToken:sessionToken];
    [self.commonDataSource.keyValueCache removeObjectForKey:cacheKey];
}

- (void)clearAllCachedResults {
    [self.commonDataSource.keyValueCache removeAllObjects];
}

- (BFTask *)_runNetworkCommandAsyncFromCache:(PFRESTCommand *)command
                       withCancellationToken:(BFCancellationToken *)cancellationToken
                               forQueryState:(PFQueryState *)queryState {
    NSString *jsonString = [self.commonDataSource.keyValueCache objectForKey:command.cacheKey
                                                                      maxAge:queryState.maxCacheAge];
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
        self.commonDataSource.keyValueCache[cacheKey] = resultString;
    }
    // Roll-forward the original result.
    return [BFTask taskWithResult:result];
}

@end
