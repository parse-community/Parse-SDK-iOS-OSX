/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUserDefaultsPersistenceGroup.h"

#import "BFTask+Private.h"
#import "PFAsyncTaskQueue.h"

@interface PFUserDefaultsPersistenceGroup () {
    PFAsyncTaskQueue *_dataAccessQueue;
    NSMutableDictionary *_dataDictionary;
}

@end

@implementation PFUserDefaultsPersistenceGroup

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithKey:key userDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithKey:(NSString *)key userDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (!self) return nil;

    _key = key;
    _userDefaults = userDefaults;

    _dataAccessQueue = [[PFAsyncTaskQueue alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - PFPersistenceGroup
///--------------------------------------

- (BFTask PF_GENERIC(NSData *)*)getDataAsyncForKey:(NSString *)key {
    return [_dataAccessQueue enqueue:^id(BFTask *task) {
        return [[self _loadUserDefaultsIfNeededAsync] continueWithSuccessBlock:^id(BFTask *task) {
            return _dataDictionary[key];
        }];
    }];
}

- (BFTask *)setDataAsync:(NSData *)data forKey:(NSString *)key {
    return [_dataAccessQueue enqueue:^id(BFTask *task) {
        return [[self _loadUserDefaultsIfNeededAsync] continueWithSuccessBlock:^id(BFTask *task) {
            _dataDictionary[key] = data;
            return [self _writeUserDefaultsAsync];
        }];
    }];
}

- (BFTask *)removeDataAsyncForKey:(NSString *)key {
    return [_dataAccessQueue enqueue:^id(BFTask *task) {
        return [[self _loadUserDefaultsIfNeededAsync] continueWithSuccessBlock:^id(BFTask *task) {
            [_dataDictionary removeObjectForKey:key];
            return [self _writeUserDefaultsAsync];
        }];
    }];
}

- (BFTask *)removeAllDataAsync {
    return [_dataAccessQueue enqueue:^id(BFTask *task) {
        return [[self _loadUserDefaultsIfNeededAsync] continueWithSuccessBlock:^id(BFTask *task) {
            [_dataDictionary removeAllObjects];
            return [self _writeUserDefaultsAsync];
        }];
    }];
}

- (BFTask *)beginLockedContentAccessAsyncToDataForKey:(NSString *)key {
    return [BFTask taskWithResult:nil];
}

- (BFTask *)endLockedContentAccessAsyncToDataForKey:(NSString *)key {
    return [BFTask taskWithResult:nil];
}

///--------------------------------------
#pragma mark - User Defaults
///--------------------------------------

- (BFTask *)_loadUserDefaultsIfNeededAsync {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        if (!_dataDictionary) {
            NSDictionary *dictionary = [_userDefaults objectForKey:self.key];
            _dataDictionary = (dictionary ? [dictionary mutableCopy] : [NSMutableDictionary dictionary]);
        }
        return nil;
    }];
}

- (BFTask *)_writeUserDefaultsAsync {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        [_userDefaults setObject:_dataDictionary forKey:self.key];
        return nil;
    }];
}

@end
