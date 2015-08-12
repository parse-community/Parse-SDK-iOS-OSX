/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <Parse/PFObject.h>
#import <Parse/PFSubclassing.h>
#else
#import <ParseOSX/PFObject.h>
#import <ParseOSX/PFSubclassing.h>
#endif

extern NSString *const PFPinKeyName;
extern NSString *const PFPinKeyObjects;

/*!
 PFPin represent internal pin implementation of PFObject's `pin`.
 */
@interface PFPin : PFObject<PFSubclassing>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSMutableArray *objects;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithName:(NSString *)name;
+ (instancetype)pinWithName:(NSString *)name;

@end
