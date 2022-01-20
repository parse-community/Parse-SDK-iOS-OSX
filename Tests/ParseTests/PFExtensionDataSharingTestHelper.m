/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFExtensionDataSharingTestHelper.h"

#import "PFApplication.h"
#import "PFTestSwizzlingUtilities.h"

@interface PFExtensionDataSharingTestHelper ()

@property (nonatomic, strong) PFTestSwizzledMethod *groupContainerSwizzledMethod;
@property (nonatomic, strong) PFTestSwizzledMethod *extensionEnvironmentSwizzledMethod;

@end

@implementation PFExtensionDataSharingTestHelper

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (NSString *)sharedTestDirectoryPath {
    NSString *library = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
    NSString *privateDocuments = [library stringByAppendingPathComponent:@"Private Documents"];
    return [privateDocuments stringByAppendingPathComponent:@"Test"];
}

+ (NSString *)sharedTestDirectoryPathForGroupIdentifier:(NSString *)groupIdentifier {
#if PF_TARGET_OS_OSX
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
#else
    return [[PFExtensionDataSharingTestHelper sharedTestDirectoryPath] stringByAppendingPathComponent:groupIdentifier];
#endif
}

#pragma mark Dealloc

- (void)dealloc {
    _extensionEnvironmentSwizzledMethod.swizzled = NO;
    _groupContainerSwizzledMethod.swizzled = NO;
}

#pragma mark Swizzling

- (void)setSwizzledGroupContainerDirectoryPath:(BOOL)swizzled {
    if (!_groupContainerSwizzledMethod && swizzled) {
        _groupContainerSwizzledMethod = [PFTestSwizzlingUtilities swizzleMethod:@selector(containerURLForSecurityApplicationGroupIdentifier:)
                                                             inClass:[NSFileManager class]
                                                          withMethod:@selector(_swizzledContainerURLForSecurityApplicationGroupIdentifier:)
                                                             inClass:[self class]];
    }
    _groupContainerSwizzledMethod.swizzled = swizzled;
}

+ (NSURL *)_swizzledContainerURLForSecurityApplicationGroupIdentifier:(NSString *)identifier {
    NSString *path = [PFExtensionDataSharingTestHelper sharedTestDirectoryPathForGroupIdentifier:identifier];
    return [NSURL fileURLWithPath:path];
}

- (void)setRunningInExtensionEnvironment:(BOOL)extensionEnvironment {
    if (self.extensionEnvironmentSwizzledMethod) {
        _extensionEnvironmentSwizzledMethod.swizzled = NO;
    }
    _extensionEnvironmentSwizzledMethod = [PFTestSwizzlingUtilities swizzleMethod:@selector(isExtensionEnvironment)
                                                               inClass:[PFApplication class]
                                                            withMethod:(extensionEnvironment
                                                                        ? @selector(_alwaysTrue)
                                                                        : @selector(_alwaysFalse))
                                                               inClass:[self class]];
    _extensionEnvironmentSwizzledMethod.swizzled = YES;
}

+ (BOOL)_alwaysTrue {
    return YES;
}

+ (BOOL)_alwaysFalse {
    return NO;
}

@end
