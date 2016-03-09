/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
@class UIApplication;
#elif PF_TARGET_OS_OSX
#import <AppKit/AppKit.h>
@compatibility_alias UIApplication NSApplication;
#endif

/**
 `PFApplication` class provides a centralized way to get the information about the current application,
 or the environment it's running in. Please note, that all device specific things - should go to <PFDevice>.
 */
@interface PFApplication : NSObject

@property (nonatomic, strong, readonly) UIApplication *systemApplication;

@property (nonatomic, assign, readonly, getter=isAppStoreEnvironment) BOOL appStoreEnvironment;
@property (nonatomic, assign, readonly, getter=isExtensionEnvironment) BOOL extensionEnvironment;

@property (nonatomic, assign) NSInteger iconBadgeNumber;

+ (instancetype)currentApplication;

@end
