/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnalytics.h"
#import "PFAnalytics_Private.h"

#if PF_TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import "BFTask+Private.h"
#import "PFAnalyticsController.h"
#import "PFAssert.h"
#import "PFEncoder.h"
#import "PFEventuallyQueue.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFAnalytics

///--------------------------------------
#pragma mark - App-Open / Push Analytics
///--------------------------------------

+ (BFTask PF_GENERIC(NSNumber *)*)trackAppOpenedWithLaunchOptions:(nullable NSDictionary *)launchOptions {
#if TARGET_OS_WATCH || TARGET_OS_TV
    NSDictionary *userInfo = nil;
#elif TARGET_OS_IOS
    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
#elif PF_TARGET_OS_OSX
    NSDictionary *userInfo = launchOptions[NSApplicationLaunchUserNotificationKey];
#endif

    return [self trackAppOpenedWithRemoteNotificationPayload:userInfo];
}

+ (void)trackAppOpenedWithLaunchOptionsInBackground:(nullable NSDictionary *)launchOptions
                                              block:(nullable PFBooleanResultBlock)block {
    [[self trackAppOpenedWithLaunchOptions:launchOptions] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask PF_GENERIC(NSNumber *)*)trackAppOpenedWithRemoteNotificationPayload:(nullable NSDictionary *)userInfo {
    return [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFAnalyticsController *controller = [Parse _currentManager].analyticsController;
        return [controller trackAppOpenedEventAsyncWithRemoteNotificationPayload:userInfo sessionToken:sessionToken];
    }] continueWithSuccessResult:@YES];
}

+ (void)trackAppOpenedWithRemoteNotificationPayloadInBackground:(nullable NSDictionary *)userInfo
                                                          block:(nullable PFBooleanResultBlock)block {
    [[self trackAppOpenedWithRemoteNotificationPayload:userInfo] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Custom Analytics
///--------------------------------------

+ (BFTask PF_GENERIC(NSNumber *)*)trackEvent:(NSString *)name {
    return [self trackEvent:name dimensions:nil];
}

+ (void)trackEventInBackground:(NSString *)name block:(nullable PFBooleanResultBlock)block {
    [self trackEventInBackground:name dimensions:nil block:block];
}

+ (BFTask PF_GENERIC(NSNumber *)*)trackEvent:(NSString *)name
                                  dimensions:(nullable NSDictionary PF_GENERIC(NSString *, NSString *) *)dimensions {
    PFParameterAssert([[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length],
                      @"A name for the custom event must be provided.");
    [dimensions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PFParameterAssert([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]],
                          @"trackEvent dimensions expect keys and values of type NSString.");
    }];

    return [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFAnalyticsController *controller = [Parse _currentManager].analyticsController;
        return [controller trackEventAsyncWithName:name dimensions:dimensions sessionToken:sessionToken];
    }] continueWithSuccessResult:@YES];
}

+ (void)trackEventInBackground:(NSString *)name
                    dimensions:(nullable NSDictionary PF_GENERIC(NSString *, NSString *) *)dimensions
                         block:(nullable PFBooleanResultBlock)block {
    [[self trackEvent:name dimensions:dimensions] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

@end
