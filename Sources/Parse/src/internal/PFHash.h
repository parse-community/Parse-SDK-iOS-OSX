/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

extern NSUInteger PFIntegerPairHash(NSUInteger a, NSUInteger b);

extern NSUInteger PFDoublePairHash(double a, double b);

extern NSUInteger PFDoubleHash(double d);

extern NSUInteger PFLongHash(unsigned long long l);

extern NSString *PFMD5HashFromData(NSData *data);
extern NSString *PFMD5HashFromString(NSString *string);
