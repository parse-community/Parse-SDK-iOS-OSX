/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPushUtilities.h"

#import <dlfcn.h>

#if TARGET_OS_IOS
#import <AudioToolbox/AudioToolbox.h>

#import "PFAlertView.h"
#endif

#import "PFInstallationPrivate.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFMacros.h"

@implementation PFPushUtilities

///--------------------------------------
#pragma mark - PFPushInternalUtils
///--------------------------------------

+ (NSString *)convertDeviceTokenToString:(id)deviceToken {
    if ([deviceToken isKindOfClass:[NSString class]]) {
        return deviceToken;
    } else {
        NSMutableString *hexString = [NSMutableString string];
        const unsigned char *bytes = [deviceToken bytes];
        for (int i = 0; i < [deviceToken length]; i++) {
            [hexString appendFormat:@"%02x", bytes[i]];
        }
        return [NSString stringWithString:hexString];
    }
}

+ (NSString *)getDeviceTokenFromKeychain {
    // Used the first time we construct the currentInstallation,
    // for backward compability with older SDKs.
    PFKeychainStore *store = [[PFKeychainStore alloc] initWithService:@"ParsePush"];
    return store[@"ParsePush"];
}

+ (void)clearDeviceToken {
    // Used in test case setup.
    [[PFInstallation currentInstallation] _clearDeviceToken];
    [[[PFKeychainStore alloc] initWithService:@"ParsePush"] removeObjectForKey:@"ParsePush"];
}

#if TARGET_OS_IOS

+ (void)showAlertViewWithTitle:(nullable NSString *)title message:(nullable NSString *)message NS_EXTENSION_UNAVAILABLE_IOS("") {
    NSString *cancelButtonTitle = NSLocalizedStringFromTableInBundle(@"OK", @"Parse",
                                                                     [NSBundle bundleForClass:[self class]],
                                                                     @"Default alert view cancel button title.");
    [PFAlertView showAlertWithTitle:title
                            message:message
                  cancelButtonTitle:cancelButtonTitle
                  otherButtonTitles:nil
                         completion:nil];
}

+ (void)playAudioWithName:(NSString *)audioFileName {
    SystemSoundID soundId = -1;

    if (audioFileName) {
        NSURL *bundlePath = [[NSBundle mainBundle] URLForResource:[audioFileName stringByDeletingPathExtension]
                                                    withExtension:[audioFileName pathExtension]];

        AudioServicesCreateSystemSoundID((__bridge CFURLRef)bundlePath, &soundId);
    }

    if (soundId != -1) {
        AudioServicesPlaySystemSound(soundId);
    }
}

+ (void)playVibrate {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#endif

@end
