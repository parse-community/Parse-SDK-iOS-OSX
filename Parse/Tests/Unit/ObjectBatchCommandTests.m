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
#import "PFRESTObjectBatchCommand.h"
#import "PFRESTObjectCommand.h"
#import "PFTestCase.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObjectBatchCommandTests : PFTestCase

@end

@implementation ObjectBatchCommandTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSArray *)sampleObjectCommands {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:25];
    while (array.count < 25) {
        PFObjectState *state = [PFObjectState stateWithParseClassName:@"a" objectId:nil isComplete:NO];
        PFRESTCommand *createCommand = [PFRESTObjectCommand createObjectCommandForObjectState:state
                                                                                      changes:@{ @"k" : @"v" }
                                                                             operationSetUUID:nil
                                                                                 sessionToken:nil];
        [array addObject:createCommand];

        state = [PFObjectState stateWithParseClassName:@"Capitan" objectId:@"yolo" isComplete:NO];
        PFRESTCommand *updateCommand = [PFRESTObjectCommand updateObjectCommandForObjectState:state
                                                                                      changes:@{ @"k1" : @"v" }
                                                                             operationSetUUID:@"asd"
                                                                                 sessionToken:nil];
        [array addObject:updateCommand];

        state = [PFObjectState stateWithParseClassName:@"Capitan" objectId:@"blah" isComplete:NO];
        PFRESTCommand *deleteCommand = [PFRESTObjectCommand deleteObjectCommandForObjectState:state
                                                                             withSessionToken:nil];
        [array addObject:deleteCommand];
    }
    return array;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testBatchCommand {
    NSArray *commands = [self sampleObjectCommands];
    PFRESTObjectBatchCommand *command = [PFRESTObjectBatchCommand batchCommandWithCommands:commands
                                                                              sessionToken:@"yolo"
                                                                                 serverURL:[NSURL URLWithString:@"https://api.parse.com/1"]];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"batch");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertEqual([command.parameters[@"requests"] count], commands.count);
    XCTAssertNotNil([command.parameters[@"requests"] firstObject][@"method"]);
    XCTAssertNotNil([command.parameters[@"requests"] firstObject][@"path"]);
    XCTAssertEqualObjects([command.parameters[@"requests"] firstObject][@"path"], @"/1/classes/a");
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testBatchCommandValidation {
    XCTAssertNotEqual(PFRESTObjectBatchCommandSubcommandsLimit, 0);

    NSMutableArray *array = [[self sampleObjectCommands] mutableCopy];
    while (array.count < PFRESTObjectBatchCommandSubcommandsLimit) {
        [array addObjectsFromArray:[self sampleObjectCommands]];
    }

    PFAssertThrowsInvalidArgumentException([PFRESTObjectBatchCommand batchCommandWithCommands:array
                                                                                 sessionToken:@"a"
                                                                                    serverURL:[NSURL URLWithString:@"https://api.parse.com/1"]]);
}

@end

NS_ASSUME_NONNULL_END
