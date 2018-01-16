/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import CoreLocation;

#define CL_DEFAULT_LATITUDE 37.7937
#define CL_DEFAULT_LONGITUDE -122.3967

@interface CLLocationManager (TestAdditions)

// Used to simulate a delay in finding + returning updated location.
+ (void)setMockingEnabled:(BOOL)enabled;
+ (void)setAuthorizationStatus:(CLAuthorizationStatus)status;

+ (void)setReturnLocation:(BOOL)doReturnLocation;
+ (void)setWillFail:(BOOL)doFail;
+ (void)reset;

- (void)overriddenStartUpdatingLocation;

@end
