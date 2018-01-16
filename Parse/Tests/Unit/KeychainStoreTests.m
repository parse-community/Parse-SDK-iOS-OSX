/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFKeychainStore.h"
#import "PFTestCase.h"

@interface KeychainStoreTests : PFTestCase

@property (nonatomic, strong) PFKeychainStore *testStore;

@end

@implementation KeychainStoreTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    self.testStore = [[PFKeychainStore alloc] initWithService:@"test"];
}

- (void)tearDown {
    [self.testStore removeAllObjects];
    self.testStore = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testSetObject {
    BOOL result = [self.testStore setObject:@"yarr" forKey:@"blah"];
    XCTAssertTrue(result, @"Set should succeed");
}

- (void)testSetObjectSubscript {
    BOOL result = [self.testStore setObject:@"yarrValue" forKeyedSubscript:@"yarrKey1"];
    XCTAssertTrue(result, @"Set should succeed");
}

- (void)testGetObject {
    NSString *key = @"yarrKey";
    NSString *value = @"yarrValue";
    self.testStore[key] = value;

    NSString *retrievedValue = [self.testStore objectForKey:key];
    XCTAssertEqualObjects(value, retrievedValue, @"Values should be equal after get");
}

- (void)testGetObjectSubscript {
    NSString *key = @"yarrKey";
    NSString *value = @"yarrValue";
    self.testStore[key] = value;

    NSString *retrievedValue = self.testStore[key];
    XCTAssertEqualObjects(value, retrievedValue, @"Values should be equal after get");
}

- (void)testSetGetComplexObject {
    NSArray *complexObject = @[ @{ @"key1" : @"value1"}, @"string2", @100500, [NSNull null] ];

    self.testStore[@"complexObject"] = complexObject;

    NSArray *retrievedComplexObject = self.testStore[@"complexObject"];
    XCTAssertTrue([retrievedComplexObject isKindOfClass:[NSArray class]], @"Complex object should properly retrieve");

    for (NSUInteger i = 0; i < retrievedComplexObject.count; i++) {
        id object = complexObject[i];
        id retrievedObject = retrievedComplexObject[i];

        XCTAssertTrue([object isEqual:retrievedObject],
                     @"Keychain store should properly retrieve objects of class - %@", [object class]);

        switch (i) {
            case 0:
            {
                NSDictionary *dictionary = object;
                NSDictionary *retrievedDictionary = retrievedObject;

                XCTAssertEqualObjects(dictionary[@"key1"], retrievedDictionary[@"key1"],
                                     @"Keychain store should properly retrieve dictionary values");
            }
                break;
            case 1:
            {
                XCTAssertEqualObjects(object, retrievedObject,
                                     @"Keychain store should properly retrieve NSString objects");
            }
                break;
            case 2:
            {
                XCTAssertEqualObjects(object, retrievedObject,
                                     @"Keychain store should properly retrieve NSNumber objects");
            }
                break;
            case 3:
            {
                XCTAssertEqual(retrievedObject, [NSNull null], @"Keychain store should properly retrieve NSNull");
            }
                break;
        }
    }

    [self.testStore removeAllObjects];
}

- (void)testRemoveObject {
    self.testStore[@"key1"] = @"value1";
    XCTAssertNotNil(self.testStore[@"key1"], @"There should be no value after removal");

    [self.testStore removeObjectForKey:@"key1"];
    XCTAssertNil(self.testStore[@"key1"], @"There should be no value after removal");
}

- (void)testRemoveObjectSubscript {
    self.testStore[@"key1"] = @"value1";
    XCTAssertNotNil(self.testStore[@"key1"], @"There should be no value after removal");

    self.testStore[@"key1"] = nil;
    XCTAssertNil(self.testStore[@"key1"], @"There should be no value after removal");
}

- (void)testRemoveAllObjects {
    self.testStore[@"key1"] = @"value1";
    self.testStore[@"key2"] = @"value2";
    XCTAssertNotNil(self.testStore[@"key1"], @"Value should be saved");
    XCTAssertNotNil(self.testStore[@"key2"], @"Value should be saved");

    [self.testStore removeAllObjects];

    XCTAssertNil(self.testStore[@"key1"], @"There should be no value after remove all");
    XCTAssertNil(self.testStore[@"key2"], @"There should be no value after remove all");
}

- (void)testThreadSafeSetObject {
    dispatch_apply(100, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        XCTAssertTrue([self.testStore setObject:@"yarr" forKey:@"pirate"]);
    });
}

- (void)testThreadSafeRemoveObject {
    dispatch_apply(100, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        XCTAssertTrue([self.testStore setObject:@"yarr" forKey:[@(i) stringValue]]);
        XCTAssertTrue([self.testStore removeObjectForKey:[@(i) stringValue]]);
    });
}

- (void)testThreadSafeRemoveAllObjects {
    dispatch_apply(100, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        XCTAssertTrue([self.testStore setObject:@"yarr" forKey:@"pirate1"]);
        XCTAssertTrue([self.testStore setObject:@"yarr" forKey:@"pirate2"]);
        XCTAssertTrue([self.testStore removeAllObjects]);
    });
}

@end
