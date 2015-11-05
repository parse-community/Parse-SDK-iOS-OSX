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

@class BFTask PF_GENERIC(__covariant BFGenericType);

@interface PFAnalyticsController : NSObject

@property (nonatomic, weak, readonly) id<PFEventuallyQueueProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFEventuallyQueueProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFEventuallyQueueProvider>)dataSource;

///--------------------------------------
/// @name Track Event
///--------------------------------------

/*!
 @abstract Tracks this application being launched. If this happened as the result of the
 user opening a push notification, this method sends along information to
 correlate this open with that push.

 @param payload      The Remote Notification payload.
 @param sessionToken Current user session token.

 @returns `BFTask` with result set to `@YES`.
 */
- (BFTask *)trackAppOpenedEventAsyncWithRemoteNotificationPayload:(NSDictionary *)payload
                                                     sessionToken:(NSString *)sessionToken;

/*!
 @abstract Tracks the occurrence of a custom event with additional dimensions.

 @param name         Event name.
 @param dimensions   `NSDictionary` of information by which to segment this event.
 @param sessionToken Current user session token.

 @returns `BFTask` with result set to `@YES`.
 */
- (BFTask *)trackEventAsyncWithName:(NSString *)name
                         dimensions:(NSDictionary *)dimensions
                       sessionToken:(NSString *)sessionToken;

@end
