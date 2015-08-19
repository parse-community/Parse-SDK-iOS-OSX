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
#import <Parse/PFFile.h>

#import "PFFileState.h"

@class BFTask;

@interface PFFile (Private)

@property (nonatomic, strong, readonly) PFFileState *state;

+ (instancetype)fileWithName:(NSString *)name url:(NSString *)url;

//
// Download
- (BFTask *)_getDataAsyncWithProgressBlock:(PFProgressBlock)block;
- (NSString *)_cachedFilePath;

@end
