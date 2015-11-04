/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFPersistenceGroup.h"

@interface PFUserDefaultsPersistenceGroup : NSObject <PFPersistenceGroup>

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithKey:(NSString *)key userDefaults:(NSUserDefaults *)userDefaults NS_DESIGNATED_INITIALIZER;

@end
