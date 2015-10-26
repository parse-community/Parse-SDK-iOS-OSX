/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

#import "PFMockURLResponse.h"

typedef BOOL(^PFMockURLProtocolRequestTestBlock)(NSURLRequest *request);
typedef PFMockURLResponse*(^PFMockURLResponseContructingBlock)(NSURLRequest *request);

@interface PFMockURLProtocol : NSURLProtocol

+ (void)mockRequestsWithResponse:(PFMockURLResponseContructingBlock)constructingBlock;
+ (void)mockRequestsPassingTest:(PFMockURLProtocolRequestTestBlock)testBlock
                   withResponse:(PFMockURLResponseContructingBlock)constructingBlock;
+ (void)mockRequestsPassingTest:(PFMockURLProtocolRequestTestBlock)testBlock
                   withResponse:(PFMockURLResponseContructingBlock)constructingBlock
                    forAttempts:(NSUInteger)attemptsCount;

+ (void)removeAllMocking;

@end
