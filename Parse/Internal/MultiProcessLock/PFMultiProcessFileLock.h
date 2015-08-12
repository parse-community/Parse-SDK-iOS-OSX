/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

//TODO: (nlutsenko) Add unit tests for this class.
@interface PFMultiProcessFileLock : NSObject <NSLocking>

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *lockFilePath;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initForFileWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;
+ (instancetype)lockForFileWithPath:(NSString *)path;

@end
