/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQuery.h"
#import "PFQueryUtilities.h"
#import "PFTestCase.h"

@interface QueryPredicateUnitTests : PFTestCase

@end

@implementation QueryPredicateUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (void)assertPredicate:(NSPredicate *)predicate hasNormalForm:(NSPredicate *)expectedDNF {
    NSPredicate *actualDNF = [PFQueryUtilities predicateByNormalizingPredicate:predicate];
    XCTAssertEqualObjects([expectedDNF predicateFormat], [actualDNF predicateFormat]);
}

- (void)assertUnsupportedPredicate:(NSPredicate *)predicate {
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"TestObject" predicate:predicate]);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testDisjunctiveNormalForm {
    [self assertPredicate:[NSPredicate predicateWithFormat:@"A = B"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A = B"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"!(3 <= X)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"X < 3"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"A BETWEEN {3, 5}"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A >= 3 AND A <= 5"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"A BETWEEN %@", @[@3, @5]]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A >= 3 AND A <= 5"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"A = B AND C = D"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A = B AND C = D"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"A = B OR C = D"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A = B OR C = D"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"(A = B AND C = D) OR (E = F AND G = H)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A = B AND C = D) OR (E = F AND G = H)"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"(A = B OR C = D) AND (E = F OR G = H)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A = B AND E = F) OR (A = B AND G = H) OR "
                           "(C = D AND E = F) OR (C = D AND G = H)"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT ((A = B AND C = D) OR (E = F AND G = H))"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A != B AND E != F) OR (A != B AND G != H) OR "
                           "(C != D AND E != F) OR (C != D AND G != H)"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT (A <= B)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A > B"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT (NOT (A = B))"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"A = B"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT (A BETWEEN %@ OR A BETWEEN %@)",
                           @[@3, @5], @[@7, @9]]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A < 3 AND A < 7) OR (A < 3 AND A > 9) OR "
                           "(A > 5 and A < 7) OR (A > 5 AND A > 9)"]];
}

- (void)testUnsupportedPredicates {
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"x = y"]];
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"NOT (text CONTAINS 'word')"]];
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"ANY x = 3"]];
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"text LIKE 'foo'"]];
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"A=1 OR B=2 OR C=3 OR D=4 OR E=5"]];
    [self assertUnsupportedPredicate:[NSPredicate predicateWithFormat:@"$foo = 'bar'"]];
}

- (void)testHoistedCommonPredicates {
    // These queries don't end up in DNF, because we can make them more efficient.

    [self assertPredicate:[NSPredicate predicateWithFormat:@"(A = B OR C = D) AND E = F"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A = B OR C = D) AND E = F"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"(A = B AND E = F) OR (C = D AND E = F)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"(A = B OR C = D) AND E = F"]];
}

- (void)testNormalizeYodaConditions {
    [self assertPredicate:[NSPredicate predicateWithFormat:@"3 <= X"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"X >= 3"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"%@ != number", @[@3, @5, @7, @9, @11]]
            hasNormalForm:[NSPredicate predicateWithFormat:@"number != %@", @[@3, @5, @7, @9, @11]]];
}

- (void)testNormalizeContainedIn {
    [self assertPredicate:[NSPredicate predicateWithFormat:@"number IN %@", @[@3, @5, @7, @9, @11]]
            hasNormalForm:[NSPredicate predicateWithFormat:@"number IN %@", @[@3, @5, @7, @9, @11]]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT (number IN %@)", @[@3, @5, @7, @9, @11]]
            hasNormalForm:[NSPredicate predicateWithFormat:@"number notContainedIn: %@", @[@3, @5, @7, @9, @11]]];

    // These rely on Mongo's conflation of containment with equality.
    [self assertPredicate:[NSPredicate predicateWithFormat:@"3 IN Y"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"Y = 3"]];

    [self assertPredicate:[NSPredicate predicateWithFormat:@"NOT (3 IN Y)"]
            hasNormalForm:[NSPredicate predicateWithFormat:@"Y != 3"]];
}

@end
