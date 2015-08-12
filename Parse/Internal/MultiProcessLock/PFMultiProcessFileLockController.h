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
@interface PFMultiProcessFileLockController : NSObject

//TODO: (nlutsenko) Re-consider using singleton here.
+ (instancetype)sharedController;

/*!
 Increments the content access counter by 1.
 If the count was 0 - this will try to acquire the file lock first.

 @param filePath Path to a file to lock access to.
 */
- (void)beginLockedContentAccessForFileAtPath:(NSString *)filePath;

/*!
 Decrements the content access counter by 1.
 If the count reaches 0 - the lock is going to be released.

 @param filePath Path to a file to lock access to.
 */
- (void)endLockedContentAccessForFileAtPath:(NSString *)filePath;

- (NSUInteger)lockedContentAccessCountForFileAtPath:(NSString *)filePath;

@end
