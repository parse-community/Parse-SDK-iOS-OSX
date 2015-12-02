/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PFKeychainStoreDefaultService;

/**
 PFKeychainStore is NSUserDefaults-like wrapper on top of Keychain.
 It supports any object, with NSCoding support. Every object is serialized using NSKeyedArchiver.

 All objects are available after the first device unlock and are not backed up.
 */
@interface PFKeychainStore : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithService:(NSString *)service NS_DESIGNATED_INITIALIZER;

- (nullable id)objectForKey:(NSString *)key;
- (nullable id)objectForKeyedSubscript:(NSString *)key;

- (BOOL)setObject:(nullable id)object forKey:(NSString *)key;
- (BOOL)setObject:(nullable id)object forKeyedSubscript:(NSString *)key;
- (BOOL)removeObjectForKey:(NSString *)key;
- (BOOL)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
