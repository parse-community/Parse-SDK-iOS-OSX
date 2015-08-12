/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Bolts/BFTask.h>

#import "PFBlockRetryer.h"
#import "PFTestCase.h"

@interface BlockRetryerTests : PFTestCase

@end

@implementation BlockRetryerTests

- (void)testInitialDelay {
    NSTimeInterval delay = [PFBlockRetryer initialRetryDelay];
    [PFBlockRetryer setInitialRetryDelay:0.1];
    XCTAssertNotEqual(delay, [PFBlockRetryer initialRetryDelay]);
}

- (void)testRetry {
    __block NSUInteger counter = 0;
    BFTask *task = [PFBlockRetryer retryBlock:^BFTask *{
        ++counter;
        if (counter == 5) {
            return [BFTask taskWithResult:@YES];
        }
        return [BFTask taskWithError:[NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil]];
    } forAttempts:5];
    [task waitUntilFinished];

    XCTAssertEqual(counter, 5);
    XCTAssertEqualObjects(task.result, @YES);
}

- (void)testRetryWithError {
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    BFTask *task = [PFBlockRetryer retryBlock:^BFTask *{
        return [BFTask taskWithError:error];
    } forAttempts:5];
    [task waitUntilFinished];
    XCTAssertEqualObjects(task.error, error);
}

@end
