/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutableFileState.h"
#import "PFTestCase.h"

@interface FileStateTests : PFTestCase

@end

@implementation FileStateTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFFileState *)sampleFileState {
    return [[PFFileState alloc] initWithName:@"yarr" urlString:@"http://yolo" mimeType:@"boom"];
}

- (void)assertFileState:(PFFileState *)state equalToState:(PFFileState *)differentState {
    XCTAssertEqualObjects(state, differentState);

    XCTAssertEqualObjects(state.name, differentState.name);
    XCTAssertEqualObjects(state.urlString, differentState.urlString);
    XCTAssertEqualObjects(state.secureURLString, differentState.secureURLString);
    XCTAssertEqualObjects(state.mimeType, differentState.mimeType);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInit {
    PFFileState *state = [[PFFileState alloc] init];
    XCTAssertNil(state.name);
    XCTAssertNil(state.urlString);
    XCTAssertNil(state.secureURLString);
    XCTAssertNil(state.mimeType);

    state = [[PFMutableFileState alloc] init];
    XCTAssertNil(state.name);
    XCTAssertNil(state.urlString);
    XCTAssertNil(state.secureURLString);
    XCTAssertNil(state.mimeType);
}

- (void)testInitWithState {
    PFFileState *sampleState = [self sampleFileState];

    PFFileState *state = [[PFFileState alloc] initWithState:sampleState];
    [self assertFileState:state equalToState:sampleState];

    state = [[PFMutableFileState alloc] initWithState:sampleState];
    [self assertFileState:state equalToState:sampleState];
}

- (void)testInitWithProperties {
    PFFileState *sampleState = [self sampleFileState];

    PFFileState *state = [[PFFileState alloc] initWithName:sampleState.name
                                                 urlString:sampleState.urlString
                                                  mimeType:sampleState.mimeType];
    [self assertFileState:state equalToState:sampleState];

    state = [[PFMutableFileState alloc] initWithName:sampleState.name
                                           urlString:sampleState.urlString
                                            mimeType:sampleState.mimeType];
    [self assertFileState:state equalToState:sampleState];
}

- (void)testWithEmptyProperties {
    PFFileState *state = [[PFFileState alloc] initWithName:nil
                                                 urlString:nil
                                                  mimeType:nil];
    XCTAssertEqualObjects(state.name, @"file");
    XCTAssertNil(state.urlString);
    XCTAssertNil(state.secureURLString);
    XCTAssertNil(state.mimeType);

    state = [[PFMutableFileState alloc] initWithName:nil
                                           urlString:nil
                                            mimeType:nil];
    XCTAssertEqualObjects(state.name, @"file");
    XCTAssertNil(state.urlString);
    XCTAssertNil(state.secureURLString);
    XCTAssertNil(state.mimeType);
}

- (void)testCopying {
    PFFileState *sampleState = [self sampleFileState];
    [self assertFileState:[sampleState copy] equalToState:sampleState];

    sampleState = [[PFMutableFileState alloc] initWithState:sampleState];
    [self assertFileState:[sampleState copy] equalToState:sampleState];
}

- (void)testMutableCopying {
    PFMutableFileState *state = [[self sampleFileState] mutableCopy];
    state.name = @"a";
    XCTAssertEqualObjects(state.name, @"a");
}

- (void)testMutableAccessors {
    PFMutableFileState *state = [[PFMutableFileState alloc] init];
    state.name = @"a";
    XCTAssertEqualObjects(state.name, @"a");
    state.urlString = @"b";
    XCTAssertEqualObjects(state.urlString, @"b");
    XCTAssertEqualObjects(state.secureURLString, @"b");
    state.mimeType = @"c";
    XCTAssertEqualObjects(state.mimeType, @"c");
}

- (void)testSecureURLString {
    PFMutableFileState *state = [[PFMutableFileState alloc] initWithName:@"a"
                                                               urlString:@"http://files.parsetfss.com/yolo.txt"
                                                                mimeType:nil];
    XCTAssertEqualObjects(state.urlString, @"http://files.parsetfss.com/yolo.txt");
    XCTAssertEqualObjects(state.secureURLString, @"https://files.parsetfss.com/yolo.txt");

    state.urlString = @"https://files.parsetfss.com/yolo.txt";
    XCTAssertEqualObjects(state.urlString, @"https://files.parsetfss.com/yolo.txt");
    XCTAssertEqualObjects(state.secureURLString, @"https://files.parsetfss.com/yolo.txt");

    state.urlString = @"http://files.parsetfss.com/yolo2.txt";
    XCTAssertEqualObjects(state.urlString, @"http://files.parsetfss.com/yolo2.txt");
    XCTAssertEqualObjects(state.secureURLString, @"https://files.parsetfss.com/yolo2.txt");

    state.urlString = nil;
    XCTAssertNil(state.urlString);
    XCTAssertNil(state.secureURLString);
}

@end
