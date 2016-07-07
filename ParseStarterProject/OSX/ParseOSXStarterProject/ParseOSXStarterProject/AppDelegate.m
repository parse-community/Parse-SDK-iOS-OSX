/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <Parse/Parse.h>

@implementation AppDelegate

#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // ****************************************************************************
    // Initialize Parse SDK
    // ****************************************************************************

    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration>  _Nonnull configuration) {
        // Add your Parse applicationId:
        configuration.applicationId = @"your_application_id";

        // Uncomment and add your clientKey (it's not required if you are using Parse Server):
        // configuration.clientKey = @"your_client_key";

        // Uncomment the following line and change to your Parse Server address;
        // configuration.server = @"https://YOUR_PARSE_SERVER/parse";

        // Enable storing and querying data from Local Datastore. Remove this line if you don't want to
        // use Local Datastore features or want to use cachePolicy.
        configuration.localDatastoreEnabled = YES;
    }]];

    [PFUser enableAutomaticUser];

    PFACL *defaultACL = [PFACL ACL];

    // If you would like all objects to be private by default, remove this line.
    defaultACL.publicReadAccess = YES;

    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    // ****************************************************************************
    // Uncomment these lines to register for Push Notifications.
    //
    // NSRemoteNotificationType types = (NSRemoteNotificationTypeAlert |
    //                                   NSRemoteNotificationTypeBadge |
    //                                   NSRemoteNotificationTypeSound);
    // [[NSApplication sharedApplication] registerForRemoteNotificationTypes:types];
    //
    // ****************************************************************************

    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
}

#pragma mark Push Notifications

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];

    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
        } else {
            NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
        }
    }];
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // Show some alert or otherwise handle the failure to register.
    NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
}

@end
