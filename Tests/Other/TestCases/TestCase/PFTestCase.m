/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"

@import Bolts.BFTask;

#import "PFTestSwizzlingUtilities.h"

@interface BFTask ()

- (void)warnOperationOnMainThread;

@end

@interface BFTask (TestAdditions)

- (void)warnOperationOnMainThreadNoOp;

@end

@implementation BFTask (TestAdditions)

- (void)warnOperationOnMainThreadNoOp {
    // Method for tests
}

@end

@implementation PFTestCase {
    NSMutableArray *_mocks;
    dispatch_queue_t _mockQueue;
}

+ (void)swizzleWarnOnMainThread {
    [PFTestSwizzlingUtilities swizzleMethod:@selector(warnOperationOnMainThread)
                                 withMethod:@selector(warnOperationOnMainThreadNoOp)
                                    inClass:[BFTask class]];
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Remove any custom test log that is attached if it's not available.
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSString *observerClassName = [userDefaults objectForKey:XCTestObserverClassKey];
        if (observerClassName && !NSClassFromString(observerClassName)) {
            [userDefaults removeObjectForKey:XCTestObserverClassKey];
            [userDefaults synchronize];
        }
#pragma clang diagnostic pop
    });
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

+ (void)setUp {
    [super setUp];

    [[self class] swizzleWarnOnMainThread];
}

+ (void)tearDown {
    [[self class] swizzleWarnOnMainThread]; // restore the original implementation

    [super tearDown];
}

- (void)setUp {
    [super setUp];

    _mocks = [[NSMutableArray alloc] init];
    _mockQueue = dispatch_queue_create("com.parse.tests.mock.queue", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown {
    dispatch_sync(_mockQueue, ^{
        [_mocks makeObjectsPerformSelector:@selector(stopMocking)];
    });

    _mocks = nil;
    _mockQueue = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (XCTestExpectation *)currentSelectorTestExpectation {
    NSInvocation *invocation = self.invocation;
    NSString *selectorName = invocation ? NSStringFromSelector(invocation.selector) : @"testExpectation";
    return [self expectationWithDescription:selectorName];
}

- (void)waitForTestExpectations {
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

///--------------------------------------
#pragma mark - File Asserts
///--------------------------------------

- (void)assertFileExists:(NSString *)path {
    BOOL isDir = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:path isDirectory:&isDir], @"%@ should exist.", path);
    XCTAssertTrue(!isDir, @"%@ should not be a directory.", path);
}

- (void)assertFileDoesntExist:(NSString *)path {
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path], @"%@ shouldn't exist.", path);
}

- (void)assertFile:(NSString *)path hasContents:(NSString *)expected {
    [self assertFileExists:path];
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    XCTAssertEqualObjects(expected, contents, @"File contents didn't match. (%@ vs %@)", expected, contents);
}

- (void)assertDirectoryExists:(NSString *)path {
    BOOL isDir = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:path isDirectory:&isDir], @"%@ should exist.", path);
    XCTAssertTrue(isDir, @"%@ should be a directory.", path);
}

- (void)assertDirectoryDoesntExist:(NSString *)path {
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path], @"%@ shouldn't exist.", path);
}

- (void)assertDirectory:(NSString *)directoryPath hasContents:(NSDictionary *)expected only:(BOOL)only {
    [self assertDirectoryExists:directoryPath];

    // Check for missing files.
    [expected enumerateKeysAndObjectsUsingBlock:^(id filename, id contents, BOOL *stop) {
        NSString *path = [directoryPath stringByAppendingPathComponent:filename];
        if ([contents isKindOfClass:[NSDictionary class]]) {
            [self assertDirectory:path hasContents:contents only:only];
        } else if ([contents isKindOfClass:[NSString class]]) {
            [self assertFile:path hasContents:contents];
        } else if ([contents isKindOfClass:[NSNull class]]) {
            [self assertFileExists:path];
        } else {
            XCTFail(@"Not sure what to do with a %@", [contents class]);
        }
    }];

    if (only) {
        // Check for unexpected files.
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
        NSString *filename = nil;
        while ((filename = [enumerator nextObject])) {
            XCTAssertNotNil(expected[filename], @"Unexpected file %@", filename);
        }
    }
}

///--------------------------------------
#pragma mark - Mock Registration
///--------------------------------------

- (void)registerMockObject:(id)mockObject {
    dispatch_sync(_mockQueue, ^{
        [_mocks addObject:mockObject];
    });
}

@end
