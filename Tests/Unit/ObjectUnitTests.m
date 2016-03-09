/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObject.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"
#import "PFObjectPrivate.h"
#import "BFTask+Private.h"

@interface ObjectUnitTests : PFUnitTestCase

@end

@implementation ObjectUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

#pragma mark Constructors

- (void)testBasicConstructors {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNotNil([[PFObject alloc] initWithClassName:@"Test"]);
    PFAssertThrowsInvalidArgumentException([[PFObject alloc] initWithClassName:nil]);

    XCTAssertNotNil([PFObject objectWithClassName:@"Test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:nil]);

    XCTAssertNotNil([PFObject objectWithoutDataWithClassName:@"Test" objectId:nil]);
    XCTAssertNotNil([PFObject objectWithoutDataWithClassName:@"Test" objectId:@"1"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithoutDataWithClassName:nil objectId:nil]);
#pragma clang diagnostic pop
}

- (void)testConstructorsWithReservedClassNames {
    PFAssertThrowsInvalidArgumentException([[PFObject alloc] initWithClassName:@"_test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:@"_test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithoutDataWithClassName:@"_test" objectId:nil]);
}

- (void)testConstructorFromDictionary {
    XCTAssertNotNil([PFObject objectWithClassName:@"Test" dictionary:nil]);
    XCTAssertNotNil([PFObject objectWithClassName:@"Test" dictionary:@{}]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:nil dictionary:nil]);
#pragma clang diagnostic pop

    PFObject *object = [PFObject objectWithClassName:@"Test" dictionary:@{ @"a" : [NSDate date] }];
    XCTAssertNotNil(object);

    NSString *string = @"foo";
    NSNumber *number = @0.75;
    NSDate *date = [NSDate date];
    NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    NSNull *null = [NSNull null];
    NSDictionary *validDictionary = @{ @"string" : string,
                                       @"number" : number,
                                       @"date" : date,
                                       @"data" : data,
                                       @"null" : null,
                                       @"object" : object };
    PFObject *object2 = [PFObject objectWithClassName:@"Test" dictionary:validDictionary];
    XCTAssertNotNil(object2);
    XCTAssertEqualObjects(string, object2[@"string"]);
    XCTAssertEqualObjects(number, object2[@"number"]);
    XCTAssertEqualObjects(date, object2[@"date"]);
    XCTAssertEqualObjects(object, object2[@"object"]);
    XCTAssertEqualObjects(null, object2[@"null"]);
    XCTAssertEqualObjects(data, object2[@"data"]);

    validDictionary = @{ @"array" : @[ object, object2 ],
                         @"dictionary" : @{@"bar" : date, @"score" : number} };
    PFObject *object3 = [PFObject objectWithClassName:@"Stuff" dictionary:validDictionary];
    XCTAssertNotNil(object3);
    XCTAssertEqualObjects(validDictionary[@"array"], object3[@"array"]);
    XCTAssertEqualObjects(validDictionary[@"dictionary"], object3[@"dictionary"]);

    // Dictionary constructor relise on constraints enforced by PFObject -setObject:forKey:
    NSDictionary *invalidDictionary = @{ @"1" : @"2",
                                         @YES : @"foo" };
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:@"Test" dictionary:invalidDictionary]);
}

#pragma mark Accessors

- (void)testObjectForKey {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    object[@"yarr"] = @"yolo";
    XCTAssertEqualObjects([object objectForKey:@"yarr"], @"yolo");
    XCTAssertEqualObjects(object[@"yarr"], @"yolo");
}

- (void)testObjectForUnavailableKey {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:nil];
    PFAssertThrowsInconsistencyException(object[@"yarr"]);
}

- (void)testSettersWithNilArguments {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    id empty = nil;

    PFAssertThrowsInvalidArgumentException([object setObject:@"foo" forKey:empty]);
    PFAssertThrowsInvalidArgumentException([object setObject:@"foo" forKeyedSubscript:empty]);
    PFAssertThrowsInvalidArgumentException(object[empty] = @"foo");

    PFAssertThrowsInvalidArgumentException([object setObject:empty forKey:@"foo"]);
    PFAssertThrowsInvalidArgumentException([object setObject:empty forKeyedSubscript:@"foo"]);
    PFAssertThrowsInvalidArgumentException(object[@"foo"] = empty);
}

- (void)testSettersWithInvalidValueTypes {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    NSSet *set = [NSSet set];
    PFAssertThrowsInvalidArgumentException([object setObject:set forKey:@"foo"]);
    PFAssertThrowsInvalidArgumentException([object setObject:set forKeyedSubscript:@"foo"]);
    PFAssertThrowsInvalidArgumentException(object[@"foo"] = set);
}

- (void)testArraySetters {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    [object addObject:@"yolo" forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @[ @"yolo" ]);

    [object addObjectsFromArray:@[ @"yolo" ] forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], (@[ @"yolo", @"yolo" ]));

    [object addUniqueObject:@"yolo" forKey:@"yarrUnique"];
    [object addUniqueObject:@"yolo" forKey:@"yarrUnique"];
    XCTAssertEqualObjects(object[@"yarrUnique"], @[ @"yolo" ]);

    [object addUniqueObjectsFromArray:@[ @"yolo1" ] forKey:@"yarrUnique"];
    [object addUniqueObjectsFromArray:@[ @"yolo", @"yolo1" ] forKey:@"yarrUnique"];
    XCTAssertEqualObjects(object[@"yarrUnique"], (@[ @"yolo", @"yolo1" ]));

    object[@"removableYarr"] = @[ @"yolo" ];
    XCTAssertEqualObjects(object[@"removableYarr"], @[ @"yolo" ]);

    [object removeObject:@"yolo" forKey:@"removableYarr"];
    XCTAssertEqualObjects(object[@"removableYarr"], @[]);

    object[@"removableYarr"] = @[ @"yolo" ];
    [object removeObjectsInArray:@[ @"yolo", @"yolo1" ] forKey:@"removableYarr"];
    XCTAssertEqualObjects(object[@"removableYarr"], @[]);
}

- (void)testIncrement {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    [object incrementKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @1);

    [object incrementKey:@"yarr" byAmount:@2];
    XCTAssertEqualObjects(object[@"yarr"], @3);

    [object incrementKey:@"yarr" byAmount:@-2];
    XCTAssertEqualObjects(object[@"yarr"], @1);
}

- (void)testRemoveObjectForKey {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    object[@"yarr"] = @1;
    XCTAssertEqualObjects(object[@"yarr"], @1);

    [object removeObjectForKey:@"yarr"];
    XCTAssertNil(object[@"yarr"]);
}

- (void)testKeyValueCoding {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    [object setValue:@"yolo" forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @"yolo");
    XCTAssertEqualObjects([object valueForKey:@"yarr"], @"yolo");
}

- (void)testKeyValueCodingFromDictionary {
    NSString *string = @"foo";
    NSNumber *number = @0.75;
    NSDate *date = [NSDate date];
    NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    NSNull *null = [NSNull null];
    NSDictionary *dictionary = @{ @"string" : string,
                                  @"number" : number,
                                  @"date" : date,
                                  @"data" : data,
                                  @"null" : null };

    PFObject *object = [PFObject objectWithClassName:@"Test"];
    [object setValuesForKeysWithDictionary:dictionary];
    XCTAssertEqualObjects(string, object[@"string"]);
    XCTAssertEqualObjects(number, object[@"number"]);
    XCTAssertEqualObjects(date, object[@"date"]);
    XCTAssertEqualObjects(null, object[@"null"]);
    XCTAssertEqualObjects(data, object[@"data"]);
}

#pragma mark Fetch

- (void)testFetchObjectWithoutObjectIdError {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object fetchInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFErrorMissingObjectId);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

#pragma mark DeleteAll

- (void)testDeleteAllWithoutObjects {
    XCTAssertTrue([PFObject deleteAll:nil]);
    XCTAssertTrue([PFObject deleteAll:@[]]);

    NSError *error = nil;
    XCTAssertTrue([PFObject deleteAll:nil error:&error]);
    XCTAssertNil(error);
    XCTAssertTrue([PFObject deleteAll:@[] error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([[[PFObject deleteAllInBackground:nil] waitForResult:nil] boolValue]);
    XCTAssertTrue([[[PFObject deleteAllInBackground:@[]] waitForResult:nil] boolValue]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject deleteAllInBackground:nil block:^(BOOL succeeded, NSError * _Nullable error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

#pragma mark Revert

- (void)testRevert {
    NSDate *date = [NSDate date];
    NSNumber *number = @0.75;
    PFObject *object = [PFObject _objectFromDictionary:@{ @"yarr" : date,
                                                          @"score" : number }
                                      defaultClassName:@"Test"
                                          completeData:YES];
    object[@"yarr"] = @"yolo";
    [object revert];
    XCTAssertEqualObjects(object[@"yarr"], date);
    XCTAssertEqualObjects(object[@"score"], number);
}

- (void)testRevertObjectForKey {
    NSDate *date = [NSDate date];
    NSNumber *number = @0.75;
    PFObject *object = [PFObject _objectFromDictionary:@{ @"yarr" : date,
                                                          @"score" : @1.0 }
                                      defaultClassName:@"Test"
                                          completeData:YES];
    object[@"yarr"] = @"yolo";
    object[@"score"] = number;
    [object revertObjectForKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], date);
    XCTAssertEqualObjects(object[@"score"], number);
}

#pragma mark Dirty

- (void)testRecursiveDirty {
    // A -> B -> A is a supported use-case, but it would crash on older SDK versions.
    PFObject *objectA = [PFObject objectWithClassName:@"A"];
    PFObject *objectB = [PFObject objectWithClassName:@"B"];

    [objectA _mergeAfterSaveWithResult:@{ @"objectId" : @"foo",
                                          @"B" : objectB }
                               decoder:[PFDecoder objectDecoder]];

    [objectB _mergeAfterSaveWithResult:@{ @"objectId" : @"bar",
                                          @"A" : objectA }
                               decoder:[PFDecoder objectDecoder]];

    XCTAssertFalse(objectA.dirty);
}

@end
