/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>
#import "PFDataProvider.h"

@class BFTask<__covariant BFGenericType>;

@interface PFCloudCodeController : NSObject

@property (nonatomic, strong, readonly) id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
#pragma mark - Cloud Functions
///--------------------------------------

/**
 Calls a Cloud Code function and returns a result of it's execution.

 @param functionName Function name to call.
 @param parameters   Parameters to pass. (can't be nil).
 @param cachePolicy  Cache Policy
 @param maxCacheAge  Max cache age
 @param sessionToken Session token to use.

 @return `BFTask` with a result set to a result of Cloud Function.
 */
- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                           cachePolicy:(PFCachePolicy)cachePolicy
                           maxCacheAge:(NSTimeInterval)maxCacheAge
                          sessionToken:(NSString *)sessionToken;

///--------------------------------------
#pragma mark - Caching
///--------------------------------------

- (nullable NSString *)cacheKeyForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken;
- (BOOL)hasCachedResultForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken;

- (void)clearCachedResultForFunction:(nonnull NSString *)functionName parameters:(nullable NSDictionary *)parameters sessionToken:(nullable NSString *)sessionToken;
- (void)clearAllCachedResults;

@end
