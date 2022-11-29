/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef PFTwitterLocalization_h
#define PFTwitterLocalization_h

#import <Foundation/Foundation.h>

#define PFTWLocalizedString(key, comment) \
[PFTwitterLocalization localizedStringForKey:key]

#endif

/**
 Used by the above macro to fetch a localized string
 */
@interface PFTwitterLocalization : NSObject

+ (NSString *)localizedStringForKey:key;

@end
