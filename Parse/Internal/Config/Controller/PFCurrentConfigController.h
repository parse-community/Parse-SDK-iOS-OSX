/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFTask;
@class PFConfig;
@class PFFileManager;

@interface PFCurrentConfigController : NSObject

@property (nonatomic, strong, readonly) PFFileManager *fileManager;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileManager:(PFFileManager *)fileManager NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithFileManager:(PFFileManager *)fileManager;

///--------------------------------------
/// @name Accessors
///--------------------------------------

- (BFTask *)getCurrentConfigAsync;
- (BFTask *)setCurrentConfigAsync:(PFConfig *)config;

- (BFTask *)clearCurrentConfigAsync;
- (BFTask *)clearMemoryCachedCurrentConfigAsync;

@end
