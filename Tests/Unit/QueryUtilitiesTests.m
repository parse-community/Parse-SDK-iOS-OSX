/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFConstants.h"
#import "PFQueryUtilities.h"
#import "PFTestCase.h"

@interface QueryUtilitiesTests : PFTestCase

@end

@implementation QueryUtilitiesTests

///--------------------------------------
#pragma mark - Utilities
///--------------------------------------

- (NSPredicate *)sampleCompoundPredicate {
    return [NSPredicate predicateWithFormat:@""];
}

- (void)assertPredicateFormat:(NSString *)toNormalize normalizesToFormat:(NSString *)expected {
    NSPredicate *normalizedPredicate = [NSPredicate predicateWithFormat:toNormalize];
    NSPredicate *expectedPredicate = [NSPredicate predicateWithFormat:expected];
    XCTAssertEqualObjects(expectedPredicate, [PFQueryUtilities predicateByNormalizingPredicate:normalizedPredicate]);
    XCTAssertEqualObjects(expectedPredicate, [PFQueryUtilities predicateByNormalizingPredicate:expectedPredicate]);
}

- (void)assertPredicateThrows:(NSString *)expected {
    NSPredicate *expectedPredicate = [NSPredicate predicateWithFormat:expected];
    XCTAssertThrows([PFQueryUtilities predicateByNormalizingPredicate:expectedPredicate]);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testReversesYodaExpressions {
    [self assertPredicateFormat:@"3 == x" normalizesToFormat:@"x == 3"];
    [self assertPredicateFormat:@"3 != x" normalizesToFormat:@"x != 3"];
    [self assertPredicateFormat:@"3 > x" normalizesToFormat:@"x < 3"];
    [self assertPredicateFormat:@"3 < x" normalizesToFormat:@"x > 3"];
    [self assertPredicateFormat:@"3 >= x" normalizesToFormat:@"x <= 3"];
    [self assertPredicateFormat:@"3 <= x" normalizesToFormat:@"x >= 3"];
    [self assertPredicateFormat:@"3 in x" normalizesToFormat:@"x = 3"];

    [self assertPredicateFormat:@"x contains y" normalizesToFormat:@"x contains y"];
}

- (void)testPushesNegatesToLeaves {
    [self assertPredicateFormat:@"!(y == 4)" normalizesToFormat:@"y != 4"];
    [self assertPredicateFormat:@"!(y == 4 || !(y == 3))" normalizesToFormat:@"y != 4 && y == 3"];
    [self assertPredicateFormat:@"!(y > 3)" normalizesToFormat:@"y <= 3"];
    [self assertPredicateFormat:@"!(y < 3)" normalizesToFormat:@"y >= 3"];
    [self assertPredicateFormat:@"!(y >= 3)" normalizesToFormat:@"y < 3"];
    [self assertPredicateFormat:@"!(y <= 3)" normalizesToFormat:@"y > 3"];
    [self assertPredicateFormat:@"!(y IN {x, y, z})" normalizesToFormat:@"y notContainedIn: {x, y, z}"];

    [self assertPredicateThrows:@"!(y MATCHES x)"];
}

- (void)testRemovesBeweens {
    [self assertPredicateFormat:@"x BETWEEN {1, 10}" normalizesToFormat:@"x >= 1 && x <= 10"];

    [self assertPredicateThrows:@"x BETWEEN y"];
    [self assertPredicateThrows:@"x BETWEEN {x, y, z}"];
}

- (void)testConvertToDNF {
    [self assertPredicateFormat:@"(x == 0) || ((x == 2) && (y != 3 || y == 2))"
               normalizesToFormat:@"(x == 0) || (x == 2 && y != 3) || (x == 2 && y == 2)"];
}

- (void)testMergeCommonPredicate {
    [self assertPredicateFormat:@"((x == 0) && (y == 1)) || ((x == 0) && (z == 1))"
               normalizesToFormat:@"(y == 1 || z == 1) && (x == 0)"];
}

- (void)testBadQueries {
    [self assertPredicateThrows:@"ANY x == y"];

    NSExpression *expression = [NSExpression expressionWithFormat:@"12345"];
    XCTAssertThrows([PFQueryUtilities predicateByNormalizingPredicate:(NSPredicate *)expression]);
}

- (void)testRemovesDoubleNegatives {
    NSPredicate *negatedPredicate = [NSPredicate predicateWithFormat:@"!(y != 5)"];
    NSPredicate *normalizedPredicate = [NSPredicate predicateWithFormat:@"y == 5"];

    XCTAssertNotEqualObjects(negatedPredicate, normalizedPredicate);

    XCTAssertEqualObjects(normalizedPredicate, [PFQueryUtilities predicateByNormalizingPredicate:negatedPredicate]);
    XCTAssertEqualObjects(normalizedPredicate, [PFQueryUtilities predicateByNormalizingPredicate:normalizedPredicate]);
}

- (void)testRegexString {
    NSString *inputString = @"Hello!";
    XCTAssertEqualObjects([PFQueryUtilities regexStringForString:inputString], @"\\QHello!\\E");

    inputString = @"Hello\\E";
    XCTAssertEqualObjects([PFQueryUtilities regexStringForString:inputString], @"\\QHello\\E\\\\E\\Q\\E");

    inputString = @"\\QHello";
    XCTAssertEqualObjects([PFQueryUtilities regexStringForString:inputString], @"\\Q\\QHello\\E");
}

- (void)testErrors {
    NSError *error = [PFQueryUtilities objectNotFoundError];

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, kPFErrorObjectNotFound);
    XCTAssertEqual(error.domain, PFParseErrorDomain);
}

@end
