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
 This category lists all methods of `PFPush` class that are synchronous, but have asynchronous counterpart,
 Calling one of these synchronous methods could potentially block the current thread for a large amount of time,
 since it might be fetching from network or saving/loading data from disk.
 */
@interface PFPush (Synchronous)

///--------------------------------------
#pragma mark - Sending Push Notifications
///--------------------------------------

/**
 *Synchronously* send this push message.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns whether the send succeeded.
 */
- (BOOL)sendPush:(NSError **)error;

/**
 *Synchronously* send a push message to a channel.

 @param channel The channel to send to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param message The message to send.
 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns whether the send succeeded.
 */
+ (BOOL)sendPushMessageToChannel:(NSString *)channel withMessage:(NSString *)message error:(NSError **)error;

/**
 Send a push message to a query.

 @param query The query to send to. The query must be a `PFInstallation` query created with `PFInstallation.+query`.
 @param message The message to send.
 @param error Pointer to an NSError that will be set if necessary.

 @return Returns whether the send succeeded.
 */
+ (BOOL)sendPushMessageToQuery:(PFQuery<PFInstallation *> *)query withMessage:(NSString *)message error:(NSError **)error;

/**
 *Synchronously* send a push message with arbitrary data to a channel.

 See the guide for information about the dictionary structure.

 @param channel The channel to send to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param data The data to send.
 @param error Pointer to an NSError that will be set if necessary.

 @return Returns whether the send succeeded.
 */
+ (BOOL)sendPushDataToChannel:(NSString *)channel withData:(NSDictionary *)data error:(NSError **)error;

/**
 *Synchronously* send a push message with arbitrary data to a query.

 See the guide for information about the dictionary structure.

 @param query The query to send to. The query must be a `PFInstallation` query
 created with `PFInstallation.+query`.
 @param data The data to send.
 @param error Pointer to an NSError that will be set if necessary.

 @return Returns whether the send succeeded.
 */
+ (BOOL)sendPushDataToQuery:(PFQuery<PFInstallation *> *)query withData:(NSDictionary *)data error:(NSError **)error;

///--------------------------------------
#pragma mark - Managing Channel Subscriptions
///--------------------------------------

/**
 *Synchronously* get all the channels that this device is subscribed to.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns an `NSSet` containing all the channel names this device is subscribed to.
 */
+ (nullable NSSet<NSString *> *)getSubscribedChannels:(NSError **)error;

/**
 *Synchrnously* subscribes the device to a channel of push notifications.

 @param channel The channel to subscribe to. The channel name must start with
 a letter and contain only letters, numbers, dashes, and underscores.
 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns whether the subscribe succeeded.
 */
+ (BOOL)subscribeToChannel:(NSString *)channel error:(NSError **)error;

/**
 *Synchronously* unsubscribes the device to a channel of push notifications.

 @param channel The channel to unsubscribe from.
 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns whether the unsubscribe succeeded.
 */
+ (BOOL)unsubscribeFromChannel:(NSString *)channel error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
