/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDateFormatter.h"
#import "PFTestCase.h"

@interface DateFormatterTests : PFTestCase

@end

@implementation DateFormatterTests

- (void)testConstructors {
    PFDateFormatter *formatter = [[PFDateFormatter alloc] init];
    XCTAssertNotNil(formatter);
}

- (void)testSharedFormatter {
    PFDateFormatter *formatter = [PFDateFormatter sharedFormatter];
    XCTAssertNotNil(formatter);
    XCTAssertEqual(formatter, [PFDateFormatter sharedFormatter]);
}

- (void)testDateDeserializationIsInvertible {
    PFDateFormatter *formatter = [[PFDateFormatter alloc] init];
    for (int i = 0; i < 5000; ++i) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:arc4random_uniform(1387152000)];

        NSString *iso = [formatter preciseStringFromDate:date];

        NSDate *dateAgain = [formatter dateFromString:iso];
        NSString *isoAgain = [formatter preciseStringFromDate:dateAgain];
        XCTAssertEqualObjects(iso, isoAgain);
    }
}

- (void)testPreciseDateFormatterConversions {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

    for (int i = 0; i < 5000; ++i) {
        NSDate *properDate = [NSDate dateWithTimeIntervalSince1970:arc4random_uniform(1387152000)];
        NSString *properString = [dateFormatter stringFromDate:properDate];

        NSString *string = [[PFDateFormatter sharedFormatter] preciseStringFromDate:properDate];
        XCTAssertEqualObjects(properString, string);

        NSDate *date = [[PFDateFormatter sharedFormatter] dateFromString:properString];
        XCTAssertEqualObjects(properDate, date);
    }
}

@end
