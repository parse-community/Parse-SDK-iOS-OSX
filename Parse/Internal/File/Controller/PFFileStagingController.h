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

NS_ASSUME_NONNULL_BEGIN

@protocol PFFileManagerProvider;

@interface PFFileStagingController : NSObject

@property (nonatomic, weak, readonly) id<PFFileManagerProvider> dataSource;

@property (nonatomic, copy, readonly) NSString *stagedFilesDirectoryPath;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFFileManagerProvider>)dataSource;

///--------------------------------------
/// @name Staging
///--------------------------------------

/**
 Moves a file from the specified path to the staging directory based off of the name and unique ID passed in.

 @param filePath The source path to stage
 @param name     The name of the file to stage
 @param uniqueId A unique ID for this file to be used when differentiating between files with the same name.

 @return A task, which yields the path of the staged file on disk.
 */
- (BFTask *)stageFileAsyncAtPath:(NSString *)filePath name:(NSString *)name uniqueId:(uint64_t)uniqueId;

/**
 Creates a file from the specified data and places it into the staging directory based off of the name and unique 
 ID passed in.

 @param fileData The data to stage
 @param name     The name of the file to stage
 @param uniqueId The unique ID for this file to be used when differentiating between files with the same name.

 @return A task, which yields the path of the staged file on disk.
 */
- (BFTask *)stageFileAsyncWithData:(NSData *)fileData name:(NSString *)name uniqueId:(uint64_t)uniqueId;

/**
 Get the staged directory path for a file with the specified name and unique ID.

 @param name     The name of the staged file
 @param uniqueId The unique ID of the staged file

 @return The path in the staged directory folder which contains the contents of the requested file.
 */
- (NSString *)stagedFilePathForFileWithName:(NSString *)name uniqueId:(uint64_t)uniqueId;

@end

NS_ASSUME_NONNULL_END
