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

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFConfig;
@class PFCurrentConfigController;
@class PFFileManager;
@protocol PFCommandRunning;

@interface PFConfigController : NSObject

@property (nonatomic, strong, readonly) PFFileManager *fileManager;
@property (nonatomic, strong, readonly) id<PFCommandRunning> commandRunner;

@property (nonatomic, strong, readonly) PFCurrentConfigController *currentConfigController;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileManager:(PFFileManager *)fileManager
                      commandRunner:(id<PFCommandRunning>)commandRunner NS_DESIGNATED_INITIALIZER;

///--------------------------------------
/// @name Fetch
///--------------------------------------

/*!
 Fetches current config from network async.

 @param sessionToken Current user session token.

 @returns `BFTask` with result set to `PFConfig`.
 */
- (BFTask *)fetchConfigAsyncWithSessionToken:(NSString *)sessionToken;

@end
