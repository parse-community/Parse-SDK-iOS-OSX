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
#import "PFMacros.h"

@class BFTask<__covariant BFGenericType>;

NS_ASSUME_NONNULL_BEGIN

@interface PFAnalyticsController : NSObject

@property (nonatomic, weak, readonly) id<PFEventuallyQueueProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFEventuallyQueueProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFEventuallyQueueProvider>)dataSource;

///--------------------------------------
#pragma mark - Track Event
///--------------------------------------

/**
 Tracks this application being launched. If this happened as the result of the
 user opening a push notification, this method sends along information to
 correlate this open with that push.

 @param payload      The Remote Notification payload.
 @param sessionToken Current user session token.

 @return `BFTask` with result set to `@YES`.
 */
- (BFTask<PFVoid> *)trackAppOpenedEventAsyncWithRemoteNotificationPayload:(nullable NSDictionary *)payload
                                                             sessionToken:(nullable NSString *)sessionToken;

/**
 Tracks the occurrence of a custom event with additional dimensions.

 @param name         Event name.
 @param dimensions   `NSDictionary` of information by which to segment this event.
 @param sessionToken Current user session token.

 @return `BFTask` with result set to `@YES`.
 */
- (BFTask<PFVoid> *)trackEventAsyncWithName:(NSString *)name
                                 dimensions:(nullable NSDictionary<NSString *, NSString *> *)dimensions
                               sessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
