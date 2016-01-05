/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import XCTest;

@interface PFTestCase : XCTestCase

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp NS_REQUIRES_SUPER;
- (void)tearDown NS_REQUIRES_SUPER;

///--------------------------------------
#pragma mark - Expectations
///--------------------------------------

- (XCTestExpectation *)currentSelectorTestExpectation;
- (void)waitForTestExpectations;

///--------------------------------------
#pragma mark - File Asserts
///--------------------------------------

- (void)assertFileExists:(NSString *)path;
- (void)assertFileDoesntExist:(NSString *)path;
- (void)assertFile:(NSString *)path hasContents:(NSString *)expected;

- (void)assertDirectoryExists:(NSString *)path;
- (void)assertDirectoryDoesntExist:(NSString *)path;

- (void)assertDirectory:(NSString *)directoryPath hasContents:(NSDictionary *)expected only:(BOOL)only;

///--------------------------------------
#pragma mark - Mocks
///--------------------------------------

- (void)registerMockObject:(id)mockObject;

@end

#define _PFRegisterMock(mockObject) [self registerMockObject:mockObject]
#define _PFMockShim(method, args...) ({ id mock = method(args); _PFRegisterMock(mock); mock; })
#define _PFOCMockWarning _Pragma("GCC warning \"Please use PF mocking methods instead of OCMock ones.\"")

#define _PFStrictClassMock(kls)         [OCMockObject mockForClass:kls]
#define _PFClassMock(kls)               [OCMockObject niceMockForClass:kls]
#define _PFStrictProtocolMock(proto)    [OCMockObject mockForProtocol:proto]
#define _PFProtocolMock(proto)          [OCMockObject niceMockForProtocol:proto]
#define _PFPartialMock(obj)             [OCMockObject partialMockForObject:obj]

#define PFStrictClassMock(...)          _PFMockShim(_PFStrictClassMock,    __VA_ARGS__)
#define PFClassMock(...)                _PFMockShim(_PFClassMock,          __VA_ARGS__)
#define PFStrictProtocolMock(...)       _PFMockShim(_PFStrictProtocolMock, __VA_ARGS__)
#define PFProtocolMock(...)             _PFMockShim(_PFProtocolMock,       __VA_ARGS__)
#define PFPartialMock(...)              _PFMockShim(_PFPartialMock,        __VA_ARGS__)

#undef OCMStrictClassMock
#undef OCMClassMock
#undef OCMStrictProtocolMock
#undef OCMProtocolMock
#undef OCMPartialMock

#define OCMStrictClassMock             _PFOCMockWarning _PFStrictClassMock
#define OCMClassMock                   _PFOCMockWarning _PFClassMock
#define OCMStrictProtocolMock          _PFOCMockWarning _PFStrictProtocolMock
#define OCMProtocolMock                _PFOCMockWarning _PFProtocolMock
#define OCMPartialMock                 _PFOCMockWarning _PFPartialMock

#define PFAssertEqualInts(a1, a2, description...) \
XCTAssertEqual((int)(a1), (int)(a2), ## description);

#define PFAssertNotEqualInts(a1, a2, description...) \
XCTAssertNotEqual((int)(a1), (int)(a2), ## description);

#define PFAssertIsKindOfClass(a1, a2, description...) \
XCTAssertTrue([a1 isKindOfClass:[a2 class]], ## description)

#define PFAssertNotKindOfClass(a1, a2, description...) \
XCTAssertFalse([a1 isKindOfClass:[a2 class]], ## description)

#define PFAssertThrowsInconsistencyException(expression, ...) \
XCTAssertThrowsSpecificNamed(expression, NSException, NSInternalInconsistencyException, __VA_ARGS__)

#define PFAssertThrowsInvalidArgumentException(expression, ...) \
XCTAssertThrowsSpecificNamed(expression, NSException, NSInvalidArgumentException, __VA_ARGS__)

#define PFAssertStringContains(a, b) XCTAssertTrue([(a) rangeOfString:(b)].location != NSNotFound)
