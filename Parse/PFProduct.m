/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFProduct.h"
#import "PFProduct+Private.h"

#import "PFAssert.h"
#import "PFObject+Subclass.h"

@implementation PFProduct

@dynamic productIdentifier;
@dynamic icon;
@dynamic title;
@dynamic subtitle;
@dynamic order;
@dynamic downloadName;

///--------------------------------------
#pragma mark - PFSubclassing
///--------------------------------------

// Validates a class name. We override this to only allow the product class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[PFProduct parseClassName]],
                      @"Cannot initialize a PFProduct with a custom class name.");
}

+ (NSString *)parseClassName {
    return @"_Product";
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

@dynamic price;
@dynamic priceLocale;
@dynamic contentPath;
@dynamic progress;

@end
