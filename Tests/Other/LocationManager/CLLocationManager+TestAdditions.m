/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "CLLocationManager+TestAdditions.h"

#import <Parse/PFConstants.h>

#import "PFTestSwizzlingUtilities.h"

@interface CLLocationManager ()

+ (void)setAuthorizationStatus:(BOOL)status forBundleIdentifier:(NSString *)bundleIdentifier;

- (void)resetApps;

@end

@implementation CLLocationManager (TestAdditions)

static BOOL returnLocation = YES;
static BOOL willFail = NO;
static BOOL mockingEnabled = NO;

///--------------------------------------
#pragma mark - Configuration
///--------------------------------------

+ (void)setMockingEnabled:(BOOL)enabled {
    // There is no ability to use real CLLocationManager on Mac, due to permission requests
#if PF_TARGET_OS_OSX
    if (!enabled) {
        return;
    }
#endif
    if (mockingEnabled != enabled) {
        mockingEnabled = enabled;

        [PFTestSwizzlingUtilities swizzleMethod:@selector(startUpdatingLocation) withMethod:@selector(overriddenStartUpdatingLocation) inClass:self];
    }
}

+ (void)setAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined) {
        // Use private API to reset all apps
        [[[CLLocationManager alloc] init] resetApps];
    } else {
        // Use private API to set the auth status, without triggering the permission request
        [self setAuthorizationStatus:status forBundleIdentifier:[NSBundle mainBundle].bundleIdentifier];
    }
}

+ (void)setReturnLocation:(BOOL)doReturnLocation {
    returnLocation = doReturnLocation;
}

+ (void)setWillFail:(BOOL)doFail {
    willFail = doFail;
}

+ (void)reset {
    [self setMockingEnabled:YES];
    returnLocation = YES;
    willFail = NO;
}

///--------------------------------------
#pragma mark - Swizzled Selector
///--------------------------------------

- (void)overriddenStartUpdatingLocation {
    if (willFail) {
        [self.delegate locationManager:self didFailWithError:[NSError errorWithDomain:kCLErrorDomain
                                                                                 code:kCLErrorLocationUnknown
                                                                             userInfo:nil]];
    } else if (returnLocation) {
        CLLocation *fakeLocation = [[CLLocation alloc] initWithLatitude:CL_DEFAULT_LATITUDE
                                                              longitude:CL_DEFAULT_LONGITUDE];
        [self.delegate locationManager:self didUpdateLocations:@[ fakeLocation ]];
    }
}

@end
