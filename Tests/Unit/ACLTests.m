/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFACLPrivate.h"
#import "PFMacros.h"
#import "PFObjectPrivate.h"
#import "PFRole.h"
#import "PFUnitTestCase.h"
#import "PFUserPrivate.h"

@interface ACLTests : PFUnitTestCase

@end

@implementation ACLTests

- (void)testConstructors {
    id mockedUser = PFStrictClassMock([PFUser class]);
    OCMStub([mockedUser objectId]).andReturn(@"1337");

    PFACL *acl = [PFACL ACL];
    XCTAssertNotNil(acl);
    XCTAssertFalse([acl getReadAccessForUser:mockedUser]);
    XCTAssertFalse([acl getWriteAccessForUser:mockedUser]);

    acl = [PFACL ACLWithUser:mockedUser];
    XCTAssertNotNil(acl);
    XCTAssertTrue([acl getReadAccessForUser:mockedUser]);
    XCTAssertTrue([acl getWriteAccessForUser:mockedUser]);
}

- (void)testShared {
    PFACL *acl = [PFACL ACL];
    XCTAssertFalse(acl.isShared);

    [acl setShared:YES];
    XCTAssertTrue(acl.isShared);
}

- (void)testPublicAccess {
    PFACL *acl = [PFACL ACL];

    XCTAssertFalse([acl getPublicReadAccess]);
    XCTAssertFalse([acl getPublicWriteAccess]);

    [acl setPublicReadAccess:YES];
    XCTAssertTrue([acl getPublicReadAccess]);

    [acl setPublicWriteAccess:YES];
    XCTAssertTrue([acl getPublicWriteAccess]);
}

- (void)testReadAccess {
    PFRole *mockedRole = PFStrictClassMock([PFRole class]);
    PFUser *mockedUser = PFStrictClassMock([PFUser class]);

    OCMStub(mockedRole.name).andReturn(@"aRoleName");
    OCMStub(mockedRole.objectId).andReturn(@"aRoleID");
    OCMStub(mockedUser.objectId).andReturn(@"aUserID");

    PFACL *acl = [PFACL ACL];

    XCTAssertFalse([acl getReadAccessForUserId:@"someUserID"]);
    XCTAssertFalse([acl getReadAccessForUser:mockedUser]);
    XCTAssertFalse([acl getReadAccessForRoleWithName:@"someRoleName"]);
    XCTAssertFalse([acl getReadAccessForRole:mockedRole]);

    [acl setReadAccess:YES forUserId:@"someUserID"];
    XCTAssertTrue([acl getReadAccessForUserId:@"someUserID"]);

    [acl setReadAccess:YES forUser:mockedUser];
    XCTAssertTrue([acl getReadAccessForUser:mockedUser]);

    [acl setReadAccess:YES forRoleWithName:@"someRoleName"];
    XCTAssertTrue([acl getReadAccessForRoleWithName:@"someRoleName"]);

    [acl setReadAccess:YES forRole:mockedRole];
    XCTAssertTrue([acl getReadAccessForRole:mockedRole]);
}

- (void)testWriteAccess {
    PFRole *mockedRole = PFStrictClassMock([PFRole class]);
    PFUser *mockedUser = PFStrictClassMock([PFUser class]);

    OCMStub(mockedRole.name).andReturn(@"aRoleName");
    OCMStub(mockedRole.objectId).andReturn(@"aRoleID");
    OCMStub(mockedUser.objectId).andReturn(@"aUserID");

    PFACL *acl = [PFACL ACL];

    XCTAssertFalse([acl getWriteAccessForUserId:@"someUserID"]);
    XCTAssertFalse([acl getWriteAccessForUser:mockedUser]);
    XCTAssertFalse([acl getWriteAccessForRoleWithName:@"someRoleName"]);
    XCTAssertFalse([acl getWriteAccessForRole:mockedRole]);

    [acl setWriteAccess:YES forUserId:@"someUserID"];
    XCTAssertTrue([acl getWriteAccessForUserId:@"someUserID"]);

    [acl setWriteAccess:YES forUser:mockedUser];
    XCTAssertTrue([acl getWriteAccessForUser:mockedUser]);

    [acl setWriteAccess:YES forRoleWithName:@"someRoleName"];
    XCTAssertTrue([acl getWriteAccessForRoleWithName:@"someRoleName"]);

    [acl setWriteAccess:YES forRole:mockedRole];
    XCTAssertTrue([acl getWriteAccessForRole:mockedRole]);
}

- (void)testLazyUser {
    PFUser *lazyUser = PFStrictClassMock([PFUser class]);

    __block NSString *userId = nil;

    OCMStub(lazyUser.objectId).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&userId];
    });
    OCMStub(lazyUser._lazy).andReturn(YES);

    __block void (^saveListener)(id, NSError *) = nil;

    OCMStub([lazyUser registerSaveListener:[OCMArg checkWithBlock:^BOOL(id obj) {
        saveListener = [obj copy];

        return obj != nil;
    }]]);

    OCMStub([lazyUser unregisterSaveListener:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:saveListener];
    }]]);

    PFACL *acl = [PFACL ACL];

    XCTAssertFalse([acl hasUnresolvedUser]);

    [acl setReadAccess:YES forUser:lazyUser];
    [acl setWriteAccess:YES forUser:lazyUser];

    XCTAssertTrue([acl hasUnresolvedUser]);

    XCTAssertTrue([acl getReadAccessForUser:lazyUser]);
    XCTAssertTrue([acl getWriteAccessForUser:lazyUser]);

    XCTAssertFalse([acl getReadAccessForUserId:@"userID"]);
    XCTAssertFalse([acl getWriteAccessForUserId:@"userID"]);

    userId = @"userID";

    saveListener(lazyUser, nil);

    XCTAssertFalse([acl hasUnresolvedUser]);
    XCTAssertTrue([acl getReadAccessForUserId:@"userID"]);
    XCTAssertTrue([acl getWriteAccessForUserId:@"userID"]);
}

- (void)testEquality {
    PFACL *a = [PFACL ACL];
    PFACL *b = [PFACL ACL];

    XCTAssertFalse([a isEqual:nil]);
    XCTAssertFalse([a isEqual:@"Hello, World!"]);

    XCTAssertTrue([a isEqual:a]);
    XCTAssertTrue([a isEqual:b]);

    [b setPublicWriteAccess:YES];

    XCTAssertFalse([a isEqual:b]);
}

- (void)testHash {
    PFACL *acl = [PFACL ACL];
    NSUInteger oldHash = [acl hash];

    [acl setReadAccess:YES forUserId:@"foo"];
    NSUInteger newHash = [acl hash];

    XCTAssertNotEqual(oldHash, newHash);
}

- (void)testCopy {
    PFACL *aclA = [PFACL ACL];
    PFACL *aclB = [aclA copy];

    XCTAssertNotEqual(aclA, aclB);
    XCTAssertEqualObjects(aclA, aclB);

    [aclB setPublicWriteAccess:YES];

    XCTAssertFalse([aclA getPublicWriteAccess]);
}

- (void)testUnsharedCopy {
    PFACL *sharedACL = [PFACL ACL];
    [sharedACL setShared:YES];
    [sharedACL setPublicReadAccess:YES];

    PFACL *unsharedACL = [sharedACL createUnsharedCopy];
    XCTAssertFalse([unsharedACL isShared]);
    XCTAssertTrue([unsharedACL getPublicReadAccess]);
}



- (void)testACLRequiresObjectId {
    PFACL *acl = [PFACL ACL];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrowsSpecificNamed([acl setReadAccess:YES forUserId:nil],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Should not be able to give permissions to nil ids.");
    XCTAssertThrowsSpecificNamed([acl setWriteAccess:YES forUserId:nil],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Should not be able to give permissions to nil ids.");
#pragma clang diagnostic pop
    PFUser *user = [PFUser user];
    XCTAssertThrowsSpecificNamed([acl setReadAccess:YES forUser:user],
                                NSException,
                                NSInvalidArgumentException,
                                @"Should not be able to give permissions to unsaved users.");
    XCTAssertThrowsSpecificNamed([acl setWriteAccess:YES forUser:user],
                                NSException,
                                NSInvalidArgumentException,
                                @"Should not be able to give permissions to unsaved users.");
}

- (void)testNSCoding {
    PFACL *acl = [PFACL ACL];
    [acl setReadAccess:NO forUserId:@"a"];
    [acl setReadAccess:YES forUserId:@"b"];
    [acl setWriteAccess:NO forUserId:@"c"];
    [acl setWriteAccess:YES forUserId:@"d"];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:acl];
    XCTAssertTrue([data length] > 0, @"Encoded data should not be empty");

    PFACL *decodedACL = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertFalse([decodedACL getReadAccessForUserId:@"a"], @"Decoded value should be the same as the encoded one.");
    XCTAssertTrue([decodedACL getReadAccessForUserId:@"b"], @"Decoded value should be the same as the encoded one.");
    XCTAssertFalse([decodedACL getWriteAccessForUserId:@"c"], @"Decoded value should be the same as the encoded one.");
    XCTAssertTrue([decodedACL getWriteAccessForUserId:@"d"], @"Decoded value should be the same as the encoded one.");
}

@end
