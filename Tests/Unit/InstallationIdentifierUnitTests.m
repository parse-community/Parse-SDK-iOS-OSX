/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFInstallationIdentifierStore_Private.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"
#import "BFTask+Private.h"
#import "PFPersistenceController.h"

@interface InstallationIdentifierUnitTests : PFUnitTestCase

@end

@implementation InstallationIdentifierUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testNewInstallationIdentifierIsLowercase {
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store getInstallationIdentifierAsync] continueWithSuccessBlock:^id(BFTask<NSString *> *task) {
        NSString *installationId = task.result;
        XCTAssertNotNil(installationId);
        XCTAssertNotEqual(installationId.length, 0);
        XCTAssertEqualObjects(installationId, [installationId lowercaseString]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCachedInstallationId {
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;

    [[store _clearCachedInstallationIdentifierAsync] waitForResult:nil];

    NSString *first = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    NSString *second = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertNotNil(first);
    XCTAssertNotNil(second);
    XCTAssertEqualObjects(first, second, @"installationId should be the same on different calls");

    [[store _clearCachedInstallationIdentifierAsync] waitForResult:nil];

    NSString *third = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertEqualObjects(first, third, @"installationId should be the same after clearing cache");

    [[store clearInstallationIdentifierAsync] waitForResult:nil];

    NSString *fourth = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertNotEqualObjects(first, fourth, @"clearing from disk should cause a new installationId");
}

- (void)testInstallationIdentifierThreadSafe {
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;
    [[store clearInstallationIdentifierAsync] waitForResult:nil];
    dispatch_apply(100, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t iteration) {
        [store getInstallationIdentifierAsync];
        [store clearInstallationIdentifierAsync];
    });
}

- (void)testInstallationIdentifierPropagatesErrorOnPersistenceFailure {
    id<PFPersistenceGroup> group = PFStrictProtocolMock(@protocol(PFPersistenceGroup));
    OCMStub([group beginLockedContentAccessAsyncToDataForKey:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:nil]);
    OCMStub([group endLockedContentAccessAsyncToDataForKey:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:nil]);
    OCMStub([group getDataAsyncForKey:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:nil]);
    OCMStub([group setDataAsync:[OCMArg isNotNil] forKey:[OCMArg isNotNil]]).andReturn([BFTask taskWithError:[[NSError alloc] init]]);

    PFPersistenceController *persistenceController = PFStrictClassMock([PFPersistenceController class]);
    OCMStub([persistenceController getPersistenceGroupAsync]).andReturn([BFTask taskWithResult:group]);

    id<PFPersistenceControllerProvider> dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    OCMStub([dataSource persistenceController]).andReturn(persistenceController);

    PFInstallationIdentifierStore *store = [[PFInstallationIdentifierStore alloc] initWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store getInstallationIdentifierAsync] continueWithBlock:^id _Nullable(BFTask<NSString *> * _Nonnull t) {
        XCTAssertTrue(t.faulted);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
