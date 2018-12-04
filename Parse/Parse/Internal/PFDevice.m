/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDevice.h"

#import <Parse/PFConstants.h>

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#elif TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif PF_TARGET_OS_OSX
#import <CoreServices/CoreServices.h>
#endif

#include <sys/sysctl.h>
#include <sys/types.h>
#include <dirent.h>

static NSString *PFDeviceSysctlByName(NSString *name) {
    const char *charName = name.UTF8String;
    NSString *string = nil;
    size_t size = 0;
    char *answer = NULL;

    do {
        if (sysctlbyname(charName, NULL, &size, NULL, 0) != 0) {
            break;
        }
        answer = (char*)malloc(size);

        if (answer == NULL) {
            break;
        }

        if (sysctlbyname(charName, answer, &size, NULL, 0) != 0) {
            break;
        }

        // We need to check if the string is null-terminated or not.
        // Documentation is silent on this fact, but in practice it actually is usually null-terminated.
        size_t length = size - (answer[size - 1] == '\0');
        string = [[NSString alloc] initWithBytes:answer length:length encoding:NSASCIIStringEncoding];
    } while(0);

    free(answer);
    return string;
}

@implementation PFDevice

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)currentDevice {
    static PFDevice *device;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [[self alloc] init];
    });
    return device;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSString *)detailedModel {
    NSString *name = PFDeviceSysctlByName(@"hw.machine");
    if (!name) {
#if TARGET_OS_WATCH
        name = [WKInterfaceDevice currentDevice].model;
#elif TARGET_OS_IOS || TARGET_OS_TV
        name = [UIDevice currentDevice].model;
#elif TARGET_OS_MAC
        name = @"Mac";
#endif
    }
    return name;
}

- (NSString *)operatingSystemFullVersion {
    NSString *version = self.operatingSystemVersion;
    NSString *build = self.operatingSystemBuild;
    if (build.length) {
        version = [version stringByAppendingFormat:@" (%@)", build];
    }
    return version;
}
- (NSString *)operatingSystemVersion {
#if TARGET_OS_IOS
    return [UIDevice currentDevice].systemVersion;
#elif TARGET_OS_WATCH || TARGET_OS_TV
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    return [NSString stringWithFormat:@"%d.%d.%d",
            (int)version.majorVersion,
            (int)version.minorVersion,
            (int)version.patchVersion];
#elif PF_TARGET_OS_OSX
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if (@available(macOS 10.10, *)) {
        NSOperatingSystemVersion version = info.operatingSystemVersion;
        return [NSString stringWithFormat:@"%d.%d.%d",
                (int)version.majorVersion,
                (int)version.minorVersion,
                (int)version.patchVersion];
    } else {
        // TODO: (nlutsenko) Remove usage of this method, when we drop support for OSX 10.9
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        SInt32 major, minor, bugfix;
        if (Gestalt(gestaltSystemVersionMajor, &major) == noErr &&
            Gestalt(gestaltSystemVersionMinor, &minor) == noErr &&
            Gestalt(gestaltSystemVersionBugFix, &bugfix) == noErr) {
            return [NSString stringWithFormat:@"%d.%d.%d", major, minor, bugfix];
        }
#pragma clang diagnostic pop
        return [[NSProcessInfo processInfo] operatingSystemVersionString];
    }
#endif
}

- (NSString *)operatingSystemBuild {
    return PFDeviceSysctlByName(@"kern.osversion");
}

- (BOOL)isJailbroken {
    BOOL jailbroken = NO;
#if TARGET_OS_IOS && !TARGET_IPHONE_SIMULATOR
    DIR *dir = opendir("/");
    if (dir != NULL) {
        jailbroken = YES;
        closedir(dir);
    }
#endif
    return jailbroken;
}

@end
