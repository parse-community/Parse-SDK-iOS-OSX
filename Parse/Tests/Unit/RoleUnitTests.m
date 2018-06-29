/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFMockURLProtocol.h"
#import "PFRelation.h"
#import "PFRole.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface RoleUnitTests : PFUnitTestCase

@end

@implementation RoleUnitTests

- (void)testConstructors {
    PFRole *role = [PFRole roleWithName:@"someName"];
    XCTAssertEqual(role.name, @"someName");
    XCTAssertNil(role.ACL);

    PFACL *acl = [PFACL ACL];
    role = [PFRole roleWithName:@"someName" acl:acl];
    XCTAssertEqual(role.name, @"someName");
    XCTAssertEqual(role.ACL, acl);
}

- (void)testInvalidConstructors {
    PFAssertThrowsInvalidArgumentException([[PFRole alloc] initWithClassName:@"YoloSwag"]);
}

- (void)testRelations {
    PFRole *parentRole = [PFRole roleWithName:@"parent" acl:nil];

    PFAssertIsKindOfClass(parentRole.roles, [PFRelation class]);
    PFAssertIsKindOfClass(parentRole.users, [PFRelation class]);
}

- (void)testInvalidName {
    PFRole *sampleRole = [PFRole objectWithoutDataWithObjectId:@"leroy"];
    PFAssertThrowsInconsistencyException(sampleRole.name = @"jenkins");

    PFAssertThrowsInvalidArgumentException([PFRole roleWithName:(NSString *)@100]);
    PFAssertThrowsInvalidArgumentException([PFRole roleWithName:@"??!!"]);
}

- (void)testCannotSave {
    [NSURLProtocol registerClass:[PFMockURLProtocol class]];

    XCTestExpectation *failedSaveExpectation = [self currentSelectorTestExpectation];
    [PFMockURLProtocol mockRequestsWithResponse:^PFMockURLResponse *(NSURLRequest *request) {
        return [PFMockURLResponse responseWithString:@"{ \"error\": \"some error\", \"code\": 101 }" statusCode:400 delay:0];
    }];

    PFRole *theRole = [[PFRole alloc] init];
    PFAssertThrowsInconsistencyException([theRole saveInBackground]);

    theRole.name = @"SomeName";
    [[theRole saveInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        [failedSaveExpectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];

    [PFMockURLProtocol removeAllMocking];
    [NSURLProtocol unregisterClass:[PFMockURLProtocol class]];
}

@end
