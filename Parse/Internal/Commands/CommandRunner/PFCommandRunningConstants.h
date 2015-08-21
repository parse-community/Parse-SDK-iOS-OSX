/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

///--------------------------------------
/// @name Running
///--------------------------------------

extern uint8_t const PFCommandRunningDefaultMaxAttemptsCount;

///--------------------------------------
/// @name Headers
///--------------------------------------

extern NSString *const PFCommandHeaderNameApplicationId;
extern NSString *const PFCommandHeaderNameClientKey;
extern NSString *const PFCommandHeaderNameClientVersion;
extern NSString *const PFCommandHeaderNameInstallationId;
extern NSString *const PFCommandHeaderNameAppBuildVersion;
extern NSString *const PFCommandHeaderNameAppDisplayVersion;
extern NSString *const PFCommandHeaderNameOSVersion;
extern NSString *const PFCommandHeaderNameSessionToken;

///--------------------------------------
/// @name HTTP Method Override
///--------------------------------------

extern NSString *const PFCommandParameterNameMethodOverride;

///--------------------------------------
/// @name Notifications
///--------------------------------------

/*!
 @abstract The name of the notification that is going to be sent before any URL request is sent.
 */
extern NSString *const PFCommandRunnerWillSendURLRequestNotification;

/*!
 @abstract The name of the notification that is going to be sent after any URL response is received.
 */
extern NSString *const PFCommandRunnerDidReceiveURLResponseNotification;

/*!
 @abstract The key of request(NSURLRequest) in the userInfo dictionary of a notification.
 */
extern NSString *const PFCommandRunnerNotificationURLRequestUserInfoKey;

/*!
 @abstract The key of response(NSHTTPURLResponse) in the userInfo dictionary of a notification.
 */
extern NSString *const PFCommandRunnerNotificationURLResponseUserInfoKey;
