/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFRESTAnalyticsCommand.h"
#import "PFTestCase.h"

@interface AnalyticsCommandTests : PFTestCase

@end

@implementation AnalyticsCommandTests

- (void)testTrackAppOpenedCommand {
    PFRESTAnalyticsCommand *command = [PFRESTAnalyticsCommand trackAppOpenedEventCommandWithPushHash:nil
                                                                                        sessionToken:nil];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"events/AppOpened");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters[@"push_hash"]);
    XCTAssertNotNil(command.parameters);
    XCTAssertNil(command.sessionToken);

    command = [PFRESTAnalyticsCommand trackAppOpenedEventCommandWithPushHash:@"yolo" sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"events/AppOpened");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"push_hash"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

- (void)testTrackEventCommand {
    PFRESTAnalyticsCommand *command = [PFRESTAnalyticsCommand trackEventCommandWithEventName:@"a"
                                                                                  dimensions:nil
                                                                                sessionToken:nil];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"events/a");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters);
    XCTAssertNil(command.sessionToken);

    command = [PFRESTAnalyticsCommand trackEventCommandWithEventName:@"a"
                                                          dimensions:@{ @"b" : @"c" }
                                                        sessionToken:@"d"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"events/a");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters);
    XCTAssertNotNil(command.parameters[@"dimensions"]);
    XCTAssertEqualObjects(command.sessionToken, @"d");
}

- (void)testCrashReportCommand {
    PFRESTAnalyticsCommand *command = [PFRESTAnalyticsCommand trackCrashReportCommandWithBreakpadDumpParameters:@{ @"a" : @"yolo" }
                                                                                                   sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"events/_CrashReport");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"breakpadDump"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

@end
