/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFApplication.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif PF_TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif
@interface PFApplication() {
    NSUInteger _iconBadgeNumber;
}
@end

@implementation PFApplication

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)currentApplication {
    static PFApplication *application;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        application = [[self alloc] init];
    });
    return application;
}

- (id)init {
    self = [super init];
    if (self) {
#if TARGET_OS_IOS
        [self.systemApplication addObserver:self forKeyPath:@"applicationIconBadgeNumber" options:NSKeyValueObservingOptionNew context:nil];
        _iconBadgeNumber = self.systemApplication.applicationIconBadgeNumber;
#endif
    }
    return self;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BOOL)isAppStoreEnvironment {
#if TARGET_OS_IOS && !TARGET_IPHONE_SIMULATOR
    return ([[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"] == nil);
#endif

    return NO;
}

- (BOOL)isExtensionEnvironment {
    return [[NSBundle mainBundle].bundlePath hasSuffix:@".appex"];
}

- (NSInteger)iconBadgeNumber {
#if TARGET_OS_WATCH || TARGET_OS_TV
    return 0;
#elif TARGET_OS_IOS
    return _iconBadgeNumber;
#elif PF_TARGET_OS_OSX
    // Make sure not to use `NSApp` here, because it doesn't work sometimes,
    // `NSApplication +sharedApplication` does though.
    NSString *badgeLabel = [[NSApplication sharedApplication] dockTile].badgeLabel;
    if (badgeLabel.length == 0) {
        return 0;
    }

    NSScanner *scanner = [NSScanner localizedScannerWithString:badgeLabel];

    NSInteger number = 0;
    [scanner scanInteger:&number];
    if (scanner.scanLocation != badgeLabel.length) {
        return 0;
    }

    return number;
#endif
}

- (void)setIconBadgeNumber:(NSInteger)iconBadgeNumber {
    if (self.iconBadgeNumber != iconBadgeNumber) {
#if TARGET_OS_IOS
        _iconBadgeNumber = iconBadgeNumber;
        dispatch_block_t block = ^{
            self.systemApplication.applicationIconBadgeNumber = iconBadgeNumber;
        };
        if ([NSThread currentThread].isMainThread) {
            block();
        } else {
            dispatch_async(dispatch_get_main_queue(), block);
        }
#elif PF_TARGET_OS_OSX
        [[NSApplication sharedApplication] dockTile].badgeLabel = [@(iconBadgeNumber) stringValue];
#endif
    }
}

#if TARGET_OS_IOS
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"applicationIconBadgeNumber"] && change) {
        _iconBadgeNumber = [change[@"new"] integerValue];
    }
}
#endif

- (UIApplication *)systemApplication {
#if TARGET_OS_WATCH
    return nil;
#else
    // Workaround to make `sharedApplication` still be called even if compiling for App Extensions or WatchKit apps.
    return [UIApplication performSelector:@selector(sharedApplication)];
#endif
}

- (void)dealloc {
#if TARGET_OS_IOS
    [self.systemApplication removeObserver:self forKeyPath:@"applicationIconBadgeNumber"];
#endif
}

@end
