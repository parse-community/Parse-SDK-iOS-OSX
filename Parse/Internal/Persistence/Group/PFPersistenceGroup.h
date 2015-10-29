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

@class BFTask PF_GENERIC(id);

NS_ASSUME_NONNULL_BEGIN

@protocol PFPersistenceGroup <NSObject>

///--------------------------------------
/// @name Data
///--------------------------------------

- (BFTask PF_GENERIC(NSData *)*)getDataAsyncForKey:(NSString *)key;

- (BFTask *)setDataAsync:(NSData *)data forKey:(NSString *)key;
- (BFTask *)removeDataAsyncForKey:(NSString *)key;

- (BFTask *)removeAllDataAsync;

///--------------------------------------
/// @name Access
///--------------------------------------

- (BFTask *)beginLockedContentAccessAsyncToDataForKey:(NSString *)key;
- (BFTask *)endLockedContentAccessAsyncToDataForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
