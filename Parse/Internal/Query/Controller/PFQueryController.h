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

@class BFCancellationToken;

@class BFTask<__covariant BFGenericType>;
@class PFQueryState;
@class PFRESTCommand;
@class PFCommandResult;
@class PFUser;

NS_ASSUME_NONNULL_BEGIN

@interface PFQueryController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> commonDataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
#pragma mark - Find
///--------------------------------------

/**
 Finds objects from network or LDS for any given query state.
 Supports cancellation and ACLed changes for a specific user.

 @param queryState        Query state to use.
 @param cancellationToken Cancellation token or `nil`.
 @param user              `user` to use for ACLs or `nil`.

 @return Task that resolves to `NSArray` of `PFObject`s.
 */
- (BFTask *)findObjectsAsyncForQueryState:(PFQueryState *)queryState
                    withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                                     user:(nullable PFUser *)user; // TODO: (nlutsenko) Pass `PFUserState` instead of user.

///--------------------------------------
#pragma mark - Count
///--------------------------------------

/**
 Counts objects from network or LDS for any given query state.
 Supports cancellation and ACLed changes for a specific user.

 @param queryState        Query state to use.
 @param cancellationToken Cancellation token or `nil`.
 @param user              `user` to use for ACLs or `nil`.

 @return Task that resolves to `NSNumber` with a count of results.
 */
- (BFTask *)countObjectsAsyncForQueryState:(PFQueryState *)queryState
                     withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                                      user:(nullable PFUser *)user; // TODO: (nlutsenko) Pass `PFUserState` instead of user.

///--------------------------------------
#pragma mark - Caching
///--------------------------------------

- (NSString *)cacheKeyForQueryState:(PFQueryState *)queryState sessionToken:(nullable NSString *)sessionToken;
- (BOOL)hasCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(nullable NSString *)sessionToken;

- (void)clearCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(nullable NSString *)sessionToken;
- (void)clearAllCachedResults;

@end

@protocol PFQueryControllerSubclass <NSObject>

/**
 Implementation should run a command on a network runner.

 @param command           Command to run.
 @param cancellationToken Cancellation token.
 @param queryState        Query state to run command for.

 @return `BFTask` instance with result of `PFCommandResult`.
 */
- (BFTask *)runNetworkCommandAsync:(PFRESTCommand *)command
             withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                     forQueryState:(PFQueryState *)queryState;

@end

NS_ASSUME_NONNULL_END
