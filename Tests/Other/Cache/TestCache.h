/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

/**
 Because OCMock is not thread-safe, let's create our own class that implements NSCache.
 Note that we don't inherit from NSCache, so we still get 'strict mock' functionality. We cannot do expectations
 this way, however.
 */
@interface TestCache : NSObject

+ (NSCache *)cache;

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)aKey;
- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;

@end
