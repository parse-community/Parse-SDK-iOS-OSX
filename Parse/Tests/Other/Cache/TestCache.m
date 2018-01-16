/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "TestCache.h"

@implementation TestCache {
    NSMutableDictionary *_cache;
    dispatch_queue_t _queue;
}

+ (NSCache *)cache {
    return (NSCache *)[[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _cache = [[NSMutableDictionary alloc] init];
    _queue = dispatch_queue_create("com.parse.test.cache", DISPATCH_QUEUE_SERIAL);

    return self;
}

- (id)objectForKey:(id)key {
    __block id results = nil;
    dispatch_sync(_queue, ^{
        results = _cache[key];
    });

    return results;
}

- (void)setObject:(id)object forKey:(id)aKey {
    dispatch_sync(_queue, ^{
        _cache[aKey] = object;
    });
}

- (void)removeObjectForKey:(id)aKey {
    dispatch_sync(_queue, ^{
        [_cache removeObjectForKey:aKey];
    });
}

- (void)removeAllObjects {
    dispatch_sync(_queue, ^{
        [_cache removeAllObjects];
    });
}

@end
