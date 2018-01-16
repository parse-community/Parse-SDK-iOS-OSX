/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"
#import "ParseInternal.h"

@interface ParseTestModule : NSObject <ParseModule>

@property (nonatomic, assign) BOOL didInitializeCalled;

@end

@implementation ParseTestModule

- (void)parseDidInitializeWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    self.didInitializeCalled = YES;
}

@end

@interface ParseModuleUnitTests : PFTestCase

@end

@implementation ParseModuleUnitTests

- (void)testModuleSelectors {
    ParseModuleCollection *collection = [[ParseModuleCollection alloc] init];

    ParseTestModule *module = [[ParseTestModule alloc] init];
    [collection addParseModule:module];

    [collection parseDidInitializeWithApplicationId:@"a" clientKey:nil];

    // Spin the run loop, as the delegate messages are being called on the main thread
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

    XCTAssertTrue(module.didInitializeCalled);
}

- (void)testWeakModuleReference {
    ParseModuleCollection *collection = [[ParseModuleCollection alloc] init];

    @autoreleasepool {
        ParseTestModule *module = [[ParseTestModule alloc] init];
        [collection addParseModule:module];
    }

    [collection parseDidInitializeWithApplicationId:@"a" clientKey:nil];

    // Run a single runloop tick to trigger the parse initializaiton.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];

    XCTAssertEqual(collection.modulesCount, 0);
}

- (void)testModuleRemove {
    ParseModuleCollection *collection = [[ParseModuleCollection alloc] init];

    ParseTestModule *moduleA = [[ParseTestModule alloc] init];
    ParseTestModule *moduleB = [[ParseTestModule alloc] init];

    [collection addParseModule:moduleA];
    [collection addParseModule:moduleB];

    [collection removeParseModule:moduleA];

    XCTAssertTrue([collection containsModule:moduleB]);
    XCTAssertFalse([collection containsModule:moduleA]);
    XCTAssertEqual(collection.modulesCount, 1);
}

@end
