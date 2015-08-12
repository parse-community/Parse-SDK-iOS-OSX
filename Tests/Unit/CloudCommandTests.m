/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFRESTCloudCommand.h"
#import "PFTestCase.h"

@interface CloudCommandTests : PFTestCase

@end

@implementation CloudCommandTests

- (void)testFunctionCommand {
    PFRESTCloudCommand *command = [PFRESTCloudCommand commandForFunction:@"a"
                                                          withParameters:nil
                                                            sessionToken:nil];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"functions/a");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters);
    XCTAssertNil(command.sessionToken);

    command = [PFRESTCloudCommand commandForFunction:@"a"
                                      withParameters:@{ @"b" : @"c" }
                                        sessionToken:@"yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"functions/a");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"b"]);
    XCTAssertEqualObjects(command.sessionToken, @"yarr");
}

@end
