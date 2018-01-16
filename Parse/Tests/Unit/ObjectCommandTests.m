/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFObjectState.h"
#import "PFRESTObjectCommand.h"
#import "PFTestCase.h"

@interface ObjectCommandTests : PFTestCase

@end

@implementation ObjectCommandTests

- (void)testGetObjectCommand {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"Yolo" objectId:@"yarr" isComplete:NO];
    PFRESTObjectCommand *command = [PFRESTObjectCommand fetchObjectCommandForObjectState:state
                                                                        withSessionToken:@"Capitan"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"classes/Yolo/yarr");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"Capitan");
}

- (void)testGetObjectCommandValidation {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"a" objectId:@"" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand fetchObjectCommandForObjectState:state
                                                                                withSessionToken:@"yolo"]);

    state = [PFObjectState stateWithParseClassName:@"" objectId:@"a" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand fetchObjectCommandForObjectState:state
                                                                                withSessionToken:@"yolo"]);

    state = [PFObjectState stateWithParseClassName:@"" objectId:@"" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand fetchObjectCommandForObjectState:state
                                                                                withSessionToken:@"yolo"]);
}

- (void)testCreateObjectCommand {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"Abc" objectId:nil isComplete:NO];
    PFRESTObjectCommand *command = [PFRESTObjectCommand createObjectCommandForObjectState:state
                                                                                  changes:@{ @"key" : @"value" }
                                                                         operationSetUUID:@"uuid"
                                                                             sessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"classes/Abc");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqualObjects(command.parameters[@"key"], @"value");
    XCTAssertEqualObjects(command.operationSetUUID, @"uuid");
    XCTAssertEqualObjects(command.sessionToken, @"yolo");

    command = [PFRESTObjectCommand createObjectCommandForObjectState:state
                                                             changes:nil
                                                    operationSetUUID:@"uuid"
                                                        sessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"classes/Abc");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.operationSetUUID, @"uuid");
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testCreateObjectCommandValidation {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"" objectId:nil isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand createObjectCommandForObjectState:state
                                                                                          changes:@{}
                                                                                 operationSetUUID:@"a"
                                                                                     sessionToken:@"b"]);
}

- (void)testUpdateObjectCommand {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"Abc" objectId:@"d" isComplete:NO];
    PFRESTObjectCommand *command = [PFRESTObjectCommand updateObjectCommandForObjectState:state
                                                                                  changes:@{ @"key" : @"value" }
                                                                         operationSetUUID:@"uuid"
                                                                             sessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"classes/Abc/d");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPUT);
    XCTAssertEqualObjects(command.parameters[@"key"], @"value");
    XCTAssertEqualObjects(command.operationSetUUID, @"uuid");
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testUpdateObjectCommandValidation {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"" objectId:@"d" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand updateObjectCommandForObjectState:state
                                                                                          changes:@{}
                                                                                 operationSetUUID:@"b"
                                                                                     sessionToken:@"c"]);

    state = [PFObjectState stateWithParseClassName:@"Abc" objectId:@"" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand updateObjectCommandForObjectState:state
                                                                                          changes:@{}
                                                                                 operationSetUUID:@"b"
                                                                                     sessionToken:@"c"]);

    state = [PFObjectState stateWithParseClassName:@"" objectId:@"" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand updateObjectCommandForObjectState:state
                                                                                          changes:@{}
                                                                                 operationSetUUID:@"b"
                                                                                     sessionToken:@"c"]);
}

- (void)testDeleteObjectCommand {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"Abc" objectId:@"yarr" isComplete:NO];
    PFRESTObjectCommand *command = [PFRESTObjectCommand deleteObjectCommandForObjectState:state
                                                                         withSessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"classes/Abc/yarr");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodDELETE);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testDeleteObjectCommandValidation {
    PFObjectState *state = [PFObjectState stateWithParseClassName:@"" objectId:@"yarr" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand deleteObjectCommandForObjectState:state
                                                                                 withSessionToken:@"yolo"]);

    state = [PFObjectState stateWithParseClassName:@"" objectId:@"" isComplete:NO];
    PFAssertThrowsInvalidArgumentException([PFRESTObjectCommand deleteObjectCommandForObjectState:state
                                                                                 withSessionToken:@"yolo"]);
}

@end
