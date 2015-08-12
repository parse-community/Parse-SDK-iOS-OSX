/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFTask;
@class PFPushState;
@protocol PFCommandRunning;

NS_ASSUME_NONNULL_BEGIN

@interface PFPushController : NSObject

@property (nonatomic, strong, readonly) id<PFCommandRunning> commandRunner;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithCommandRunner:(id<PFCommandRunning>)commandRunner;

///--------------------------------------
/// @name Sending Push
///--------------------------------------

/*!
 Requests push notification to be sent for a given state.

 @param state        State to use to send notifications.
 @param sessionToken Current user session token.

 @returns `BFTask` with result set to `NSNumber` with `BOOL` identifying whether the request succeeded.
 */
- (BFTask *)sendPushNotificationAsyncWithState:(PFPushState *)state sessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
