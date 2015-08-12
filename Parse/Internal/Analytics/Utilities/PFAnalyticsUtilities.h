/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@interface PFAnalyticsUtilities : NSObject

/*!
 Serializes and hexdigests an alert payload into a "push_hash" identifier
 for use in Analytics.
 Limitedly flexible - the payload is the value under the "alert" key in the
 "aps" hash of a remote notification, so we can reasonably assume that the
 complexity of its structure is limited to that accepted by Apple (in its
 "The Notification Payload" docs)

 @param payload `alert` value from a push notification.

 @returns md5 identifier.
 */
+ (NSString *)md5DigestFromPushPayload:(id)payload;

@end
