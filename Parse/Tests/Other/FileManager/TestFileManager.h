/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

@interface TestFileManager : NSObject

+ (NSFileManager *)fileManager;

- (NSData *)contentsAtPath:(NSString *)path;
- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attr;
- (BOOL) removeItemAtURL:(NSURL *)URL error:(NSError **)error;
- (BOOL)createDirectoryAtURL:(NSURL *)url
 withIntermediateDirectories:(BOOL)createIntermediates
                  attributes:(NSDictionary *)attributes
                       error:(NSError **)error;
- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)path;
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error;

@end
