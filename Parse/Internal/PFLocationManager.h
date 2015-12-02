/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class CLLocation;
@class CLLocationManager;

#if TARGET_OS_IPHONE

@class UIApplication;

#endif

typedef void(^PFLocationManagerLocationUpdateBlock)(CLLocation *location, NSError *error);

/**
 PFLocationManager is an internal class which wraps a CLLocationManager and
 returns an updated CLLocation via the provided block.

 When -addBlockForCurrentLocation is called, the CLLocationManager's
 -startUpdatingLocations is called, and upon CLLocationManagerDelegate callback
 (either success or failure), any handlers that were passed to this class will
 be called _once_ with the updated location, then removed. The CLLocationManager
 stopsUpdatingLocation upon a single failure or success case, so that the next
 location request is guaranteed a speedily returned CLLocation.
 */
@interface PFLocationManager : NSObject

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithSystemLocationManager:(CLLocationManager *)manager;

#if TARGET_OS_IPHONE

- (instancetype)initWithSystemLocationManager:(CLLocationManager *)manager
                                  application:(UIApplication *)application
                                       bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

#endif

///--------------------------------------
#pragma mark - Current Location
///--------------------------------------

- (void)addBlockForCurrentLocation:(PFLocationManagerLocationUpdateBlock)handler;

@end
