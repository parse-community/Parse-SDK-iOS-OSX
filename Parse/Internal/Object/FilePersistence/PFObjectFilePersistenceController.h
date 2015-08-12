/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFDataProvider.h"

@class BFTask;
@class PFObject;

@interface PFObjectFilePersistenceController : NSObject

@property (nonatomic, weak, readonly) id<PFFileManagerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFFileManagerProvider>)dataSource;

///--------------------------------------
/// @name Objects
///--------------------------------------

/*!
 Loads and creates a PFObject from file.

 @param key File name to use.

 @returns `BFTask` with `PFObject` or `nil` result.
 */
- (BFTask *)loadPersistentObjectAsyncForKey:(NSString *)key;

/*!
 Saves a given object to a file with name.

 @param object Object to save.
 @param key    File name to use.

 @returns `BFTask` with `nil` result.
 */
- (BFTask *)persistObjectAsync:(PFObject *)object forKey:(NSString *)key;

@end
