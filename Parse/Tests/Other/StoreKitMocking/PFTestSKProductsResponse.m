/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSKProductsResponse.h"

#import "PFAssert.h"

@interface PFTestSKProductsResponse ()

@property (nonatomic, copy) NSArray *products;
@property (nonatomic, copy) NSArray *invalidProductIdentifiers;

@end

@implementation PFTestSKProductsResponse

@synthesize products = _products;
@synthesize invalidProductIdentifiers = _invalidProductIdentifiers;

- (instancetype)init {
    return [self initWithProducts:nil invalidProductIdentifiers:nil];
}

- (instancetype)initWithProducts:(NSArray *)products
       invalidProductIdentifiers:(NSArray *)invalidProductIdentifiers {
    self = [super init];
    if (!self) return nil;

    _products = [products copy];
    _invalidProductIdentifiers = [invalidProductIdentifiers copy];

    return self;
}

@end
