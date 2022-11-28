/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <PFConstants.h>

#import "PFDataProvider.h"
#import "PFMacros.h"

@class BFTask<__covariant BFGenericType>;
@class PFObject;

NS_ASSUME_NONNULL_BEGIN

@interface PFObjectBatchController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchObjectsAsync:(nullable NSArray *)objects withSessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
#pragma mark - Delete
///--------------------------------------

- (BFTask *)deleteObjectsAsync:(nullable NSArray *)objects withSessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
#pragma mark - Utilities
///--------------------------------------

+ (nullable NSArray *)uniqueObjectsArrayFromArray:(nullable NSArray *)objects omitObjectsWithData:(BOOL)omitFetched;
+ (NSArray *)uniqueObjectsArrayFromArray:(NSArray *)objects usingFilter:(BOOL (^)(PFObject *object))filter;

@end

NS_ASSUME_NONNULL_END
