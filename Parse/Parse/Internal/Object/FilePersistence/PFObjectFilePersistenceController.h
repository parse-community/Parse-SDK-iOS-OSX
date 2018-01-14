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

#import "PFDataProvider.h"
#import "PFMacros.h"

@class BFTask<__covariant BFGenericType>;
@class PFObject;

@interface PFObjectFilePersistenceController : NSObject

@property (nonatomic, weak, readonly) id<PFPersistenceControllerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFPersistenceControllerProvider>)dataSource;

///--------------------------------------
#pragma mark - Objects
///--------------------------------------

/**
 Loads and creates a PFObject from file.

 @param key File name to use.

 @return `BFTask` with `PFObject` or `nil` result.
 */
- (BFTask<PFObject *> *)loadPersistentObjectAsyncForKey:(NSString *)key;

/**
 Saves a given object to a file with name.

 @param object Object to save.
 @param key    File name to use.

 @return `BFTask` with `nil` result.
 */
- (BFTask *)persistObjectAsync:(PFObject *)object forKey:(NSString *)key;

/**
 Removes a given object.

 @param key Key to use.

 @return `BFTask` with `nil` result.
 */
- (BFTask *)removePersistentObjectAsyncForKey:(NSString *)key;

@end
