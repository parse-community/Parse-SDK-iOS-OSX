/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDecoder.h"
#import "PFFieldOperation.h"
#import "PFFieldOperationDecoder.h"
#import "PFObject.h"
#import "PFTestCase.h"

@interface FieldOperationDecoderTests : PFTestCase

@end

@implementation FieldOperationDecoderTests

- (void)testConstructors {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];
    XCTAssertNotNil(decoder);
}

- (void)testDefaultDecoder {
    XCTAssertNotNil([PFFieldOperationDecoder defaultDecoder]);
    XCTAssertEqual([PFFieldOperationDecoder defaultDecoder], [PFFieldOperationDecoder defaultDecoder]);
}

- (void)testDecodingUnknownOperation {
    XCTAssertThrows([[PFFieldOperationDecoder defaultDecoder] decode:@{ @"__op" : @"Yarr" }
                                                         withDecoder:[PFDecoder objectDecoder]]);
}

- (void)testDecodingIncrementOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Increment",
                                  @"amount" : @100500 };
    PFIncrementOperation *operation = (PFIncrementOperation *)[decoder decode:dictionary
                                                                  withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFIncrementOperation class]);
    XCTAssertEqualObjects(operation.amount, @100500);
}

- (void)testDecodingAddOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Add",
                                  @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ] };
    PFAddOperation *operation = (PFAddOperation *)[decoder decode:dictionary
                                                      withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFAddOperation class]);
    XCTAssertEqualObjects([[operation.objects firstObject] parseClassName], @"Yolo");
}

- (void)testDecodingAddUniqueOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"AddUnique",
                                  @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ] };
    PFAddUniqueOperation *operation = (PFAddUniqueOperation *)[decoder decode:dictionary
                                                                  withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFAddUniqueOperation class]);
    XCTAssertEqualObjects([[operation.objects firstObject] parseClassName], @"Yolo");
}

- (void)testDecodingRemoveOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Remove",
                                  @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ] };
    PFRemoveOperation *operation = (PFRemoveOperation *)[decoder decode:dictionary
                                                            withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFRemoveOperation class]);
    XCTAssertEqualObjects([[operation.objects firstObject] parseClassName], @"Yolo");
}

- (void)testDecodingDeleteOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Delete" };
    PFDeleteOperation *operation = (PFDeleteOperation *)[decoder decode:dictionary
                                                            withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFDeleteOperation class]);
}

- (void)testDecodingBatchOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Batch",
                                  @"ops" : @[ @{@"__op" : @"AddRelation",
                                                @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ]},
                                              @{@"__op" : @"RemoveRelation",
                                                @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ]} ]
                                  };
    PFRelationOperation *operation = (PFRelationOperation *)[decoder decode:dictionary
                                                                withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFRelationOperation class]);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqualObjects([[operation.relationsToAdd anyObject] parseClassName], @"Yolo");
    XCTAssertEqual(operation.relationsToAdd.count, 1);
    XCTAssertEqualObjects([[operation.relationsToRemove anyObject] parseClassName], @"Yolo");
    XCTAssertEqual(operation.relationsToRemove.count, 1);
}

- (void)testDecodingDecodedBatchOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"Batch",
                                  @"ops" : @[ [PFRelationOperation addRelationToObjects:@[ [PFObject objectWithClassName:@"Yolo"] ]],
                                              [PFRelationOperation removeRelationToObjects:@[ [PFObject objectWithClassName:@"Yolo"] ]] ]
                                  };
    PFRelationOperation *operation = (PFRelationOperation *)[decoder decode:dictionary
                                                                withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFRelationOperation class]);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqualObjects([[operation.relationsToAdd anyObject] parseClassName], @"Yolo");
    XCTAssertEqual(operation.relationsToAdd.count, 1);
    XCTAssertEqualObjects([[operation.relationsToRemove anyObject] parseClassName], @"Yolo");
    XCTAssertEqual(operation.relationsToRemove.count, 1);
}

- (void)testDecodingAddRelationOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"AddRelation",
                                  @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ] };
    PFRelationOperation *operation = (PFRelationOperation *)[decoder decode:dictionary
                                                                withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFRelationOperation class]);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqual(operation.relationsToAdd.count, 1);
    XCTAssertEqualObjects([[operation.relationsToAdd anyObject] parseClassName], @"Yolo");
}

- (void)testDecodingRemoveRelationOperations {
    PFFieldOperationDecoder *decoder = [[PFFieldOperationDecoder alloc] init];

    NSDictionary *dictionary = @{ @"__op" : @"RemoveRelation",
                                  @"objects" : @[ [PFObject objectWithClassName:@"Yolo"] ] };
    PFRelationOperation *operation = (PFRelationOperation *)[decoder decode:dictionary
                                                                withDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFRelationOperation class]);
    XCTAssertEqualObjects(operation.targetClass, @"Yolo");
    XCTAssertEqual(operation.relationsToRemove.count, 1);
    XCTAssertEqualObjects([[operation.relationsToRemove anyObject] parseClassName], @"Yolo");
}

@end
