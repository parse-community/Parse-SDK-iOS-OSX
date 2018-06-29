/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookTestCase.h"

@implementation PFFacebookTestCase {
    NSMutableArray *_mocks;
    dispatch_queue_t _mockQueue;
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    _mocks = [[NSMutableArray alloc] init];
    _mockQueue = dispatch_queue_create("com.parse.tests.mock.queue", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown {
    dispatch_sync(_mockQueue, ^{
        [_mocks makeObjectsPerformSelector:@selector(stopMocking)];
    });

    _mocks = nil;
    _mockQueue = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (XCTestExpectation *)currentSelectorTestExpectation {
    NSInvocation *invocation = self.invocation;
    NSString *selectorName = invocation ? NSStringFromSelector(invocation.selector) : @"testExpectation";
    return [self expectationWithDescription:selectorName];
}

- (void)waitForTestExpectations {
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

///--------------------------------------
#pragma mark - Mock Registration
///--------------------------------------

- (void)registerMockObject:(id)mockObject {
    dispatch_sync(_mockQueue, ^{
        [_mocks addObject:mockObject];
    });
}

@end
