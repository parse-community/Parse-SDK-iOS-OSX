/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"

#import <OCMock/OCMock.h>

#import "PFFileDataStream.h"

@interface FileDataStreamTests : PFTestCase

@end

@implementation FileDataStreamTests

- (NSString *)temporaryFilePath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"datainputstream.dat"];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:[self temporaryFilePath] error:NULL];

    [super tearDown];
}

- (void)testWillNotReadLastByte {
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:[self temporaryFilePath] append:NO];
    NSInputStream *inputStream = (NSInputStream *)[[PFFileDataStream alloc] initWithFileAtPath:[self temporaryFilePath]];

    const uint8_t toWrite[16] = {
        0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
        0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF
    };
    uint8_t toRead[sizeof(toWrite)] = { 0 };
    size_t size = sizeof(toWrite);

    [outputStream open];
    [inputStream open];

    XCTAssertEqual(size, [outputStream write:toWrite maxLength:size]);

    XCTAssertEqual(size - 1, [inputStream read:toRead maxLength:size]);
    XCTAssertEqual(0, memcmp(toRead, toWrite, size - 1));

    XCTAssertEqual(0, [inputStream read:toRead maxLength:size]);

    [(PFFileDataStream *)inputStream stopBlocking];

    XCTAssertEqual(1, [inputStream read:toRead maxLength:size]);

    XCTAssertEqual(toWrite[size - 1], toRead[0]);

    [inputStream close];
    [outputStream close];
}

- (void)testDelegate {
    id mockedDelegate = PFStrictProtocolMock(@protocol(NSStreamDelegate));

    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:[self temporaryFilePath] append:NO];
    NSInputStream *inputStream = (NSInputStream *)[[PFFileDataStream alloc] initWithFileAtPath:[self temporaryFilePath]];

    const uint8_t toWrite[16] = {
        0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
        0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF
    };
    uint8_t toRead[sizeof(toWrite)] = { 0 };
    size_t size = sizeof(toWrite);

    [outputStream open];
    [outputStream write:toWrite maxLength:size];
    [outputStream close];

    inputStream.delegate = mockedDelegate;
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    OCMExpect([mockedDelegate stream:inputStream handleEvent:NSStreamEventOpenCompleted]);
    OCMExpect([mockedDelegate stream:inputStream handleEvent:NSStreamEventHasBytesAvailable]);
    [inputStream open];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    OCMVerifyAll(mockedDelegate);

    XCTAssertEqual(size - 1, [inputStream read:toRead maxLength:size]);
    XCTAssertEqual(0, [inputStream read:toRead maxLength:size]);

    OCMExpect([mockedDelegate stream:inputStream handleEvent:NSStreamEventHasBytesAvailable]);
    [(PFFileDataStream *)inputStream stopBlocking];
    OCMVerifyAll(mockedDelegate);

    OCMExpect([mockedDelegate stream:inputStream handleEvent:NSStreamEventEndEncountered]);
    XCTAssertEqual(1, [inputStream read:toRead maxLength:size]);
    XCTAssertEqual(0, [inputStream read:toRead maxLength:size]);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    OCMVerifyAll(mockedDelegate);

    [inputStream close];
}

@end
