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

#import "PFMacros.h"

@class BFExecutor;
@class BFTask PF_GENERIC(__covariant BFGenericType);

typedef NS_OPTIONS(uint8_t, PFFileManagerOptions) {
    PFFileManagerOptionSkipBackup = 1 << 0,
};

@interface PFFileManager : NSObject

///--------------------------------------
/// @name Class
///--------------------------------------

+ (BOOL)isApplicationGroupContainerReachableForGroupIdentifier:(NSString *)applicationGroup;

+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(NSString *)path;
+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(NSString *)path
                                   withOptions:(PFFileManagerOptions)options
                                      executor:(BFExecutor *)executor;

+ (BFTask *)writeStringAsync:(NSString *)string toFile:(NSString *)filePath;
+ (BFTask *)writeDataAsync:(NSData *)data toFile:(NSString *)filePath;

+ (BFTask *)copyItemAsyncAtPath:(NSString *)fromPath toPath:(NSString *)toPath;
+ (BFTask *)moveItemAsyncAtPath:(NSString *)fromPath toPath:(NSString *)toPath;

+ (BFTask *)moveContentsOfDirectoryAsyncAtPath:(NSString *)fromPath
                             toDirectoryAtPath:(NSString *)toPath
                                      executor:(BFExecutor *)executor;

+ (BFTask *)removeItemAtPathAsync:(NSString *)path;
+ (BFTask *)removeItemAtPathAsync:(NSString *)path withFileLock:(BOOL)useFileLock;
+ (BFTask *)removeDirectoryContentsAsyncAtPath:(NSString *)path;

///--------------------------------------
/// @name Instance
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                   applicationGroupIdentifier:(NSString *)applicationGroupIdentifier NS_DESIGNATED_INITIALIZER;

/*!
 Returns <Application Home>/Library/Private Documents/Parse
 for non-user generated data that shouldn't be deleted by iOS, such as "offline data".

 See https://developer.apple.com/library/ios/#qa/qa1699/_index.html
 */
- (NSString *)parseDefaultDataDirectoryPath;
- (NSString *)parseLocalSandboxDataDirectoryPath;

/*!
 The path including directories that we save data to for a given filename.
 If the file isn't found in the new "Private Documents" location, but is in the old "Documents" location,
 moves it and returns the new location.
 */
- (NSString *)parseDataItemPathForPathComponent:(NSString *)pathComponent;

- (NSString *)parseCacheItemPathForPathComponent:(NSString *)component;

@end
