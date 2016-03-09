/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFPush.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFPush` that are deprecated and will be removed in the near future.
 */
@interface PFPush (Deprecated)

///--------------------------------------
#pragma mark - Sending Push Notifications
///--------------------------------------

/**
 *Asynchronously* send a push message to a channel.

 @param channel The channel to send to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param message The message to send.
 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFPush.+sendPushMessageToChannelInBackground:withMessage:block:` instead.
 */
+ (void)sendPushMessageToChannelInBackground:(NSString *)channel
                                 withMessage:(NSString *)message
                                      target:(nullable id)target
                                    selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFPush.+sendPushMessageToChannelInBackground:withMessage:block:` instead.");

/**
 *Asynchronously* send this push message and calls the given callback.

 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFPush.-sendPushInBackgroundWithTarget:selector:` instead.
 */
- (void)sendPushInBackgroundWithTarget:(nullable id)target
                              selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFPush.-sendPushInBackgroundWithTarget:selector:` instead.");

/**
 *Asynchronously* send a push message with arbitrary data to a channel.

 See the guide for information about the dictionary structure.

 @param channel The channel to send to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param data The data to send.
 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFPush.+sendPushDataToChannelInBackground:withData:block:` instead.
 */
+ (void)sendPushDataToChannelInBackground:(NSString *)channel
                                 withData:(NSDictionary *)data
                                   target:(nullable id)target
                                 selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFPush.+sendPushDataToChannelInBackground:withData:block:` instead.");

///--------------------------------------
#pragma mark - Managing Channel Subscriptions
///--------------------------------------

/**
 *Asynchronously* get all the channels that this device is subscribed to.

 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSSet *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.

 @deprecated Please use `PFPush.+getSubscribedChannelsInBackgroundWithBlock:` instead.
 */
+ (void)getSubscribedChannelsInBackgroundWithTarget:(id)target
                                           selector:(SEL)selector PARSE_DEPRECATED("Please use `PFPush.+getSubscribedChannelsInBackgroundWithBlock:` instead.");

/**
 *Asynchronously* subscribes the device to a channel of push notifications and calls the given callback.

 @param channel The channel to subscribe to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFPush.+subscribeToChannelInBackground:block:` instead.
 */
+ (void)subscribeToChannelInBackground:(NSString *)channel
                                target:(nullable id)target
                              selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFPush.+subscribeToChannelInBackground:block:` instead.");

/**
 *Asynchronously* unsubscribes the device from a channel of push notifications and calls the given callback.

 @param channel The channel to unsubscribe from.
 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFPush.+unsubscribeFromChannelInBackground:block:` instead.
 */
+ (void)unsubscribeFromChannelInBackground:(NSString *)channel
                                    target:(nullable id)target
                                  selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFPush.+unsubscribeFromChannelInBackground:block:` instead.");

@end

NS_ASSUME_NONNULL_END
