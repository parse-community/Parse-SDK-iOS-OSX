/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import Cocoa

import Parse

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Enable storing and querying data from Local Datastore.
        // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
        Parse.enableLocalDatastore()

        // ****************************************************************************
        // Uncomment and fill in with your Parse credentials:
        // [Parse setApplicationId:@"your_application_id" clientKey:@"your_client_key"];
        // ****************************************************************************

        PFUser.enableAutomaticUser()

        let defaultACL: PFACL = PFACL()
        // If you would like all objects to be private by default, remove this line.
        defaultACL.publicReadAccess = true

        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)

        // ****************************************************************************
        // Uncomment these lines to register for Push Notifications.
        //
        // let types = NSRemoteNotificationType.Alert |
        //             NSRemoteNotificationType.Badge |
        //             NSRemoteNotificationType.Sound;
        // NSApplication.sharedApplication().registerForRemoteNotificationTypes(types)
        //
        // ****************************************************************************

        PFAnalytics.trackAppOpenedWithLaunchOptions(nil)
    }

    func application(application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()

        PFPush.subscribeToChannelInBackground("") { (succeeded: Bool, error: NSError?) in
            if succeeded {
                print("ParseStarterProject successfully subscribed to push notifications on the broadcast channel.\n");
            } else {
                print("ParseStarterProject failed to subscribe to push notifications on the broadcast channel with error = %@.\n", error)
            }
        }
    }

    func application(application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("application:didFailToRegisterForRemoteNotificationsWithError: %@\n", error)
    }

    // ****************************************************************************
    // Uncomment these lines to track Push Notifications open rate in Analytics.
    //
    //  Swift 1.2
    //    func application(application: NSApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    //        PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
    //    }
    //
    //  Swift 2.0
    //    func application(application: NSApplication, didReceiveRemoteNotification userInfo: [String : AnyObject]) {
    //        PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
    //    }
}
