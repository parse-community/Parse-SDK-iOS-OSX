/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFMutablePushState.h"
#import "PFMutableQueryState.h"
#import "PFRESTPushCommand.h"
#import "PFTestCase.h"

@interface PushCommandTests : PFTestCase

@end

NS_ASSUME_NONNULL_BEGIN

@implementation PushCommandTests

- (void)testEmptyPushCommand {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqualObjects(command.parameters[@"where"], @{});
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandChannels {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.channels = [NSSet setWithObject:@"El Capitan!"];

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqualObjects(command.parameters[@"channels"], @[ @"El Capitan!" ]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandQuery {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"_Installation"];
    [queryState setEqualityConditionWithObject:@"value" forKey:@"key"];
    state.queryState = queryState;

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqualObjects(command.parameters[@"where"], @{ @"key" : @"value" });
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandExpirationDate {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.expirationDate = [NSDate date];

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"expiration_time"]);
    XCTAssertNil(command.parameters[@"expiration_interval"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandExpirationTimeInterval {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.expirationTimeInterval = @100500;

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters[@"expiration_time"]);
    XCTAssertNotNil(command.parameters[@"expiration_interval"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandPushDate {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.pushDate = [NSDate dateWithTimeIntervalSinceNow:1.0];

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters[@"expiration_time"]);
    XCTAssertNil(command.parameters[@"expiration_interval"]);
    XCTAssertNotNil(command.parameters[@"push_time"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testPushCommandPayload {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.payload = @{ @"alert" : @"yolo" };

    PFRESTPushCommand *command = [PFRESTPushCommand sendPushCommandWithPushState:state sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"push");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqualObjects(command.parameters[@"data"], state.payload);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

@end

NS_ASSUME_NONNULL_END
