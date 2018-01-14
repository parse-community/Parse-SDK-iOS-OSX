/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFRESTFileCommand.h"
#import "PFTestCase.h"

@interface FileCommandTests : PFTestCase

@end

@implementation FileCommandTests

- (void)testUploadFileCommand {
    PFRESTFileCommand *command = [PFRESTFileCommand uploadCommandForFileWithName:@"a" sessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"files/a");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

@end
