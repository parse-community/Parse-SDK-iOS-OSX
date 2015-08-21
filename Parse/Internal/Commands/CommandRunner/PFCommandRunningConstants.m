/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandRunningConstants.h"

uint8_t const PFCommandRunningDefaultMaxAttemptsCount = 5;

NSString *const PFCommandHeaderNameApplicationId = @"X-Parse-Application-Id";
NSString *const PFCommandHeaderNameClientKey = @"X-Parse-Client-Key";
NSString *const PFCommandHeaderNameClientVersion = @"X-Parse-Client-Version";
NSString *const PFCommandHeaderNameInstallationId = @"X-Parse-Installation-Id";
NSString *const PFCommandHeaderNameAppBuildVersion = @"X-Parse-App-Build-Version";
NSString *const PFCommandHeaderNameAppDisplayVersion = @"X-Parse-App-Display-Version";
NSString *const PFCommandHeaderNameOSVersion = @"X-Parse-OS-Version";
NSString *const PFCommandHeaderNameSessionToken = @"X-Parse-Session-Token";

NSString *const PFCommandParameterNameMethodOverride = @"_method";

///--------------------------------------
#pragma mark - Notifications
///--------------------------------------

NSString *const PFCommandRunnerWillSendURLRequestNotification = @"PFCommandRunnerWillSendURLRequestNotification";
NSString *const PFCommandRunnerDidReceiveURLResponseNotification = @"PFCommandRunnerDidReceiveURLResponseNotification";
NSString *const PFCommandRunnerNotificationURLRequestUserInfoKey = @"PFCommandRunnerNotificationURLRequestUserInfoKey";
NSString *const PFCommandRunnerNotificationURLResponseUserInfoKey = @"PFCommandRunnerNotificationURLResponseUserInfoKey";
