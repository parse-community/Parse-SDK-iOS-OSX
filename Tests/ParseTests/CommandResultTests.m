/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandResult.h"
#import "PFTestCase.h"

@interface CommandResultTests : PFTestCase

@end

@implementation CommandResultTests

- (void)testConstructors {
    NSDictionary *result = @{ @"a" : @"b" };
    NSString *resultString = @"yolo";
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];

    PFCommandResult *commandResult = [[PFCommandResult alloc] initWithResult:result
                                                                resultString:resultString
                                                                httpResponse:response];
    XCTAssertNotNil(commandResult);
    XCTAssertEqualObjects(commandResult.result, result);
    XCTAssertEqualObjects(commandResult.resultString, resultString);
    XCTAssertEqualObjects(commandResult.httpResponse, response);

    commandResult = [PFCommandResult commandResultWithResult:result
                                                resultString:resultString
                                                httpResponse:response];
    XCTAssertNotNil(commandResult);
    XCTAssertEqualObjects(commandResult.result, result);
    XCTAssertEqualObjects(commandResult.resultString, resultString);
    XCTAssertEqualObjects(commandResult.httpResponse, response);
}

@end
