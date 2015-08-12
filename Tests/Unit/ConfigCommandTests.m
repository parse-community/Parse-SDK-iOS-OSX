/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFRESTConfigCommand.h"
#import "PFTestCase.h"

@interface ConfigCommandTests : PFTestCase

@end

@implementation ConfigCommandTests

- (void)testConfigFetchCommand {
    PFRESTConfigCommand *command = [PFRESTConfigCommand configFetchCommandWithSessionToken:@"a"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"config");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"a");
}

- (void)testConfigUpdateCommand {
    PFRESTConfigCommand *command = [PFRESTConfigCommand configUpdateCommandWithConfigParameters:@{ @"a" : @"b" }
                                                                                   sessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"config");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPUT);
    XCTAssertNotNil(command.parameters[@"params"][@"a"]);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

@end
