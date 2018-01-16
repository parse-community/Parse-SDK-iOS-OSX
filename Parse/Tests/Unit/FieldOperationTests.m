/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFFieldOperation.h"
#import "PFObject.h"
#import "PFTestCase.h"

@interface FieldOperationTests : PFTestCase

@end

@implementation FieldOperationTests

///--------------------------------------
#pragma mark - FieldOperation
///--------------------------------------

- (void)testFieldOperationConstructors {
    PFFieldOperation *operation = [[PFFieldOperation alloc] init];
    XCTAssertNotNil(operation);
}

- (void)testFieldOperationEncoding {
    PFFieldOperation *operation = [[PFFieldOperation alloc] init];
    XCTAssertThrows([operation encodeWithObjectEncoder:[PFEncoder objectEncoder]]);
}

- (void)testFieldOperationMerge {
    PFFieldOperation *operation = [[PFFieldOperation alloc] init];
    XCTAssertThrows([operation mergeWithPrevious:nil]);
    XCTAssertThrows([operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);
}

- (void)testFieldOperationApply {
    PFFieldOperation *operation = [[PFFieldOperation alloc] init];
    XCTAssertThrows([operation applyToValue:@1 forKey:@"a"]);
}

///--------------------------------------
#pragma mark - SetOperation
///--------------------------------------

- (void)testSetOperationConstructors {
    PFSetOperation *operation = [[PFSetOperation alloc] initWithValue:@"yarr"];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.value, @"yarr");

    operation = [PFSetOperation setWithValue:@"yarr"];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.value, @"yarr");
}

- (void)testSetOperationDescription {
    PFSetOperation *operation = [[PFSetOperation alloc] initWithValue:@"yarr"];
    XCTAssertTrue([[operation description] rangeOfString:@"yarr"].location != NSNotFound);
}

- (void)testSetOperationConstructorsValidation {
    PFAssertThrowsInvalidArgumentException([[PFSetOperation alloc] initWithValue:nil]);
    PFAssertThrowsInvalidArgumentException([PFSetOperation setWithValue:nil]);
}

- (void)testSetOperationMerge {
    PFSetOperation *operation = [PFSetOperation setWithValue:@"yarr"];
    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[[PFDeleteOperation alloc] init]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

- (void)testSetOperationEncoding {
    PFEncoder *encoder = PFStrictClassMock([PFEncoder class]);
    OCMStub([encoder encodeObject:[OCMArg isEqual:@"yarr"]]).andReturn(@"yolo");

    PFSetOperation *operation = [PFSetOperation setWithValue:@"yarr"];
    XCTAssertEqualObjects([operation encodeWithObjectEncoder:encoder], @"yolo");
}

///--------------------------------------
#pragma mark - DeleteOperation
///--------------------------------------

- (void)testDeleteOperationConstructors {
    PFDeleteOperation *operation = [[PFDeleteOperation alloc] init];
    XCTAssertNotNil(operation);

    operation = [PFDeleteOperation operation];
    XCTAssertNotNil(operation);
}

- (void)testDeleteOperationDescription {
    PFDeleteOperation *operation = [PFDeleteOperation operation];
    XCTAssertTrue([[operation description] rangeOfString:@"delete"].location != NSNotFound);
}

- (void)testDeleteOperationEncoding {
    PFDeleteOperation *operation = [PFDeleteOperation operation];

    NSDictionary *encoded = [operation encodeWithObjectEncoder:nil];
    XCTAssertEqualObjects(encoded, @{ @"__op" : @"Delete" });

    encoded = [operation encodeWithObjectEncoder:[PFEncoder objectEncoder]];
    XCTAssertEqualObjects(encoded, @{ @"__op" : @"Delete" });
}

- (void)testDeleteOperationMerge {
    PFDeleteOperation *operation = [PFDeleteOperation operation];
    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[[PFDeleteOperation alloc] init]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertEqual(operation, [operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

///--------------------------------------
#pragma mark - IncrementOperation
///--------------------------------------

- (void)testIncrementOperationConstructors {
    PFIncrementOperation *operation = [[PFIncrementOperation alloc] initWithAmount:@100500];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.amount, @100500);

    operation = [PFIncrementOperation incrementWithAmount:@100500];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.amount, @100500);
}

- (void)testIncrementOperationDescription {
    PFIncrementOperation *operation = [PFIncrementOperation incrementWithAmount:@100500];
    XCTAssertTrue([[operation description] rangeOfString:@"100500"].location != NSNotFound);
}

- (void)testIncrementOperationEncoding {
    PFIncrementOperation *operation = [PFIncrementOperation incrementWithAmount:@100500];

    NSDictionary *properEncodedDictionary = @{ @"__op" : @"Increment",
                                               @"amount" : @100500 };

    NSDictionary *encoded = [operation encodeWithObjectEncoder:nil];
    XCTAssertEqualObjects(encoded, properEncodedDictionary);

    encoded = [operation encodeWithObjectEncoder:[PFEncoder objectEncoder]];
    XCTAssertEqualObjects(encoded, properEncodedDictionary);
}

- (void)testIncrementOperationMerge {
    PFIncrementOperation *operation = [PFIncrementOperation incrementWithAmount:@50];
    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);

    PFSetOperation *set = (PFSetOperation *)[operation mergeWithPrevious:[[PFDeleteOperation alloc] init]];
    XCTAssertEqualObjects(set.value, @50);
    set = (PFSetOperation *)[operation mergeWithPrevious:[PFSetOperation setWithValue:@1]];
    XCTAssertEqualObjects(set.value, @51);

    PFAssertThrowsInvalidArgumentException([operation mergeWithPrevious:[PFSetOperation setWithValue:@"1"]]);

    //TODO: (nlutsenko) Convert to XCTAssertEqualObjects when PFFieldOperation supports proper `isEqual:`
    PFIncrementOperation *increment = (PFIncrementOperation *)[operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]];
    XCTAssertEqualObjects(increment.amount, @51);

    PFAssertThrowsInconsistencyException([operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    PFAssertThrowsInconsistencyException([operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);
    PFAssertThrowsInconsistencyException([operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);

    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

///--------------------------------------
#pragma mark - AddOperation
///--------------------------------------

- (void)testAddOperationConstructors {
    PFAddOperation *operation = [PFAddOperation addWithObjects:@[ @"yarr" ]];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.objects, @[ @"yarr" ]);
}

- (void)testAddOperationDescription {
    PFAddOperation *operation = [PFAddOperation addWithObjects:@[ @"yarr" ]];
    XCTAssertTrue([[operation description] rangeOfString:@"yarr"].location != NSNotFound);
}

- (void)testAddOperationEncoding {
    PFEncoder *encoder = PFStrictClassMock([PFEncoder class]);
    OCMStub([encoder encodeObject:[OCMArg isEqual:@[ @"yarr" ]]]).andReturn(@"yolo");

    PFAddOperation *operation = [PFAddOperation addWithObjects:@[ @"yarr" ]];
    XCTAssertThrows([operation encodeWithObjectEncoder:nil]);
    XCTAssertEqualObjects([operation encodeWithObjectEncoder:encoder], (@{ @"__op" : @"Add",
                                                                           @"objects" : @"yolo" }));
}

- (void)testAddOperationMerge {
    PFAddOperation *operation = [PFAddOperation addWithObjects:@[ @"yarr" ]];

    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);

    XCTAssertThrows([operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);
    PFSetOperation *setResult = (PFSetOperation *)[operation mergeWithPrevious:[PFSetOperation setWithValue:@[]]];
    XCTAssertEqualObjects(setResult.value, @[ @"yarr" ]);

    PFSetOperation *deleteResult = (PFSetOperation *)[operation mergeWithPrevious:[[PFDeleteOperation alloc] init]];
    XCTAssertEqualObjects(deleteResult.value, @[ @"yarr" ]);

    XCTAssertThrows([operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);

    PFAddOperation *addResult = (PFAddOperation *)[operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]];
    XCTAssertEqualObjects(addResult.objects, (@[ @"yolo", @"yarr" ]));

    XCTAssertThrows([operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);

    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

///--------------------------------------
#pragma mark - AddUniqueOperation
///--------------------------------------

- (void)testAddUniqueOperationConstructors {
    PFAddUniqueOperation *operation = [PFAddUniqueOperation addUniqueWithObjects:@[ @"yarr" ]];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.objects, @[ @"yarr" ]);
}

- (void)testAddUniqueOperationDescription {
    PFAddUniqueOperation *operation = [PFAddUniqueOperation addUniqueWithObjects:@[ @"yarr" ]];
    XCTAssertTrue([[operation description] rangeOfString:@"yarr"].location != NSNotFound);
}

- (void)testAddUniqueOperationEncoding {
    PFEncoder *encoder = PFStrictClassMock([PFEncoder class]);
    OCMStub([encoder encodeObject:[OCMArg isEqual:@[ @"yarr" ]]]).andReturn(@"yolo");

    PFAddUniqueOperation *operation = [PFAddUniqueOperation addUniqueWithObjects:@[ @"yarr" ]];
    XCTAssertThrows([operation encodeWithObjectEncoder:nil]);
    XCTAssertEqualObjects([operation encodeWithObjectEncoder:encoder], (@{ @"__op" : @"AddUnique",
                                                                           @"objects" : @"yolo" }));
}

- (void)testAddUniqueOperationMerge {
    PFAddUniqueOperation *operation = [PFAddUniqueOperation addUniqueWithObjects:@[ @"yarr" ]];

    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);

    XCTAssertThrows([operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);
    PFSetOperation *setResult = (PFSetOperation *)[operation mergeWithPrevious:[PFSetOperation setWithValue:@[]]];
    XCTAssertEqualObjects(setResult.value, @[ @"yarr" ]);

    PFSetOperation *deleteResult = (PFSetOperation *)[operation mergeWithPrevious:[[PFDeleteOperation alloc] init]];
    XCTAssertEqualObjects(deleteResult.value, @[ @"yarr" ]);

    XCTAssertThrows([operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);

    PFAddUniqueOperation *addResult = (PFAddUniqueOperation *)[operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]];
    XCTAssertEqualObjects(addResult.objects, (@[ @"yarr", @"yolo" ]));

    XCTAssertThrows([operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);

    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

///--------------------------------------
#pragma mark - RemoveOperation
///--------------------------------------

- (void)testRemoveOperationConstructors {
    PFRemoveOperation *operation = [PFRemoveOperation removeWithObjects:@[ @"yarr" ]];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.objects, @[ @"yarr" ]);
}

- (void)testRemoveOperationDescription {
    PFRemoveOperation *operation = [PFRemoveOperation removeWithObjects:@[ @"yarr" ]];
    XCTAssertTrue([[operation description] rangeOfString:@"yarr"].location != NSNotFound);
}

- (void)testRemoveOperationEncoding {
    PFEncoder *encoder = PFStrictClassMock([PFEncoder class]);
    OCMStub([encoder encodeObject:[OCMArg isEqual:@[ @"yarr" ]]]).andReturn(@"yolo");

    PFRemoveOperation *operation = [PFRemoveOperation removeWithObjects:@[ @"yarr" ]];
    XCTAssertThrows([operation encodeWithObjectEncoder:nil]);
    XCTAssertEqualObjects([operation encodeWithObjectEncoder:encoder], (@{ @"__op" : @"Remove",
                                                                           @"objects" : @"yolo" }));
}

- (void)testRemoveOperationMerge {
    PFRemoveOperation *operation = [PFRemoveOperation removeWithObjects:@[ @"yarr" ]];

    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);

    XCTAssertThrows([operation mergeWithPrevious:[PFSetOperation setWithValue:@1]]);
    PFSetOperation *setResult = (PFSetOperation *)[operation mergeWithPrevious:[PFSetOperation setWithValue:@[ @"yarr" ]]];
    XCTAssertEqualObjects(setResult.value, @[]);

    XCTAssertThrows([operation mergeWithPrevious:[[PFDeleteOperation alloc] init]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);

    PFRemoveOperation *removeResult = (PFRemoveOperation *)[operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]];
    XCTAssertEqualObjects(removeResult.objects, (@[ @"yolo", @"yarr" ]));

    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRelationOperation removeRelationToObjects:@[]]]);
}

///--------------------------------------
#pragma mark - RelationOperation
///--------------------------------------

- (void)testRelationOperationConstructors {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];

    PFRelationOperation *operation = [PFRelationOperation addRelationToObjects:@[ object ]];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqualObjects(operation.relationsToAdd, [NSSet setWithObject:object]);
    XCTAssertEqual(operation.relationsToRemove.count, 0);

    operation = [PFRelationOperation removeRelationToObjects:@[ object ]];
    XCTAssertNotNil(operation);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqual(operation.relationsToAdd.count, 0);
    XCTAssertEqualObjects(operation.relationsToRemove, [NSSet setWithObject:object]);

    PFObject *badObject = [PFObject objectWithClassName:@"Yarr"];
    PFAssertThrowsInvalidArgumentException([PFRelationOperation addRelationToObjects:(@[ object, badObject ])]);
    PFAssertThrowsInvalidArgumentException([PFRelationOperation removeRelationToObjects:(@[ object, badObject ])]);
}

- (void)testRelationOperationDescription {
    PFRelationOperation *operation = [PFRelationOperation addRelationToObjects:@[ [PFObject objectWithClassName:@"Yolo"] ]];
    XCTAssertTrue([[operation description] rangeOfString:@"Yolo"].location != NSNotFound);

    operation = [PFRelationOperation removeRelationToObjects:@[ [PFObject objectWithClassName:@"Yolo"] ]];
    XCTAssertTrue([[operation description] rangeOfString:@"Yolo"].location != NSNotFound);
}

- (void)testRelationOperationEncoding {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    PFEncoder *encoder = PFStrictClassMock([PFEncoder class]);
    OCMStub([encoder encodeObject:OCMOCK_ANY]).andReturn(@"yolo");

    PFRelationOperation *operation = [PFRelationOperation addRelationToObjects:@[ object, object ]];
    NSDictionary *encoded = [operation encodeWithObjectEncoder:encoder];
    XCTAssertEqualObjects(encoded, (@{ @"__op" : @"AddRelation",
                                       @"objects" : @[ @"yolo" ] }));

    operation = [PFRelationOperation removeRelationToObjects:@[ object, object ]];
    encoded = [operation encodeWithObjectEncoder:encoder];
    XCTAssertEqualObjects(encoded, (@{ @"__op" : @"RemoveRelation",
                                       @"objects" : @[ @"yolo" ] }));

    PFObject *anotherObject = [PFObject objectWithClassName:@"Yolo"];

    operation = (PFRelationOperation *)[operation mergeWithPrevious:[PFRelationOperation addRelationToObjects:@[ anotherObject ]]];
    encoded = [operation encodeWithObjectEncoder:encoder];
    XCTAssertEqualObjects(encoded, (@{ @"__op" : @"Batch",
                                       @"ops" : @[ @{@"__op" : @"AddRelation", @"objects" : @[ @"yolo" ]},
                                                   @{@"__op" : @"RemoveRelation", @"objects" : @[ @"yolo" ]} ] }));

    XCTAssertThrows([[PFRelationOperation addRelationToObjects:@[]] encodeWithObjectEncoder:encoder]);
    XCTAssertThrows([[PFRelationOperation removeRelationToObjects:@[]] encodeWithObjectEncoder:encoder]);
}

- (void)testRelationOperationMerge {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    PFRelationOperation *operation = [PFRelationOperation addRelationToObjects:@[ object ]];

    XCTAssertEqual(operation, [operation mergeWithPrevious:nil]);
    XCTAssertThrows([operation mergeWithPrevious:[[PFDeleteOperation alloc] init]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFIncrementOperation incrementWithAmount:@1]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFAddOperation addWithObjects:@[ @"yolo" ]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFAddUniqueOperation addUniqueWithObjects:@[ @"yolo" ]]]);
    XCTAssertThrows([operation mergeWithPrevious:[PFRemoveOperation removeWithObjects:@[ @"yolo" ]]]);
}

@end
