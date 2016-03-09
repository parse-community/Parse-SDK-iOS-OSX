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

NS_ASSUME_NONNULL_BEGIN

@class BFTask<__covariant BFGenericType>;
@class PFPin;

@interface PFPinningObjectStore : NSObject

@property (nonatomic, weak, readonly) id<PFOfflineStoreProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFOfflineStoreProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)storeWithDataSource:(id<PFOfflineStoreProvider>)dataSource;

///--------------------------------------
#pragma mark - Pin
///--------------------------------------

/**
 Gets pin with name equals to given name.

 @param name Pin Name.

 @return `BFTask` with `PFPin` result if pinning succeeds.
 */
- (BFTask<PFPin *> *)fetchPinAsyncWithName:(NSString *)name;

/**
 Pins given objects to the pin. Creates new pin if the pin with such name is not found.

 @param objects         Array of `PFObject`s to pin.
 @param name            Pin Name.
 @param includeChildren Whether children of `objects` should be pinned as well.

 @return `BFTask` with no result.
 */
- (BFTask<PFVoid> *)pinObjectsAsync:(nullable NSArray *)objects
                        withPinName:(NSString *)name
                    includeChildren:(BOOL)includeChildren;

///--------------------------------------
#pragma mark - Unpin
///--------------------------------------

/**
 Unpins given array of objects from the pin.

 @param objects Objects to unpin.
 @param name    Pin name.

 @return `BFTask` with no result.
 */
- (BFTask<PFVoid> *)unpinObjectsAsync:(nullable NSArray *)objects withPinName:(NSString *)name;

/**
 Unpins all objects from the pin.

 @param name Pin name.

 @return `BFTask` with no result.
 */
- (BFTask<PFVoid> *)unpinAllObjectsAsyncWithPinName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
