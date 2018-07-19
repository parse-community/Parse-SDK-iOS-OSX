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

    @IBOutlet weak var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // ****************************************************************************
        // Initialize Parse SDK
        // ****************************************************************************

        let configuration = ParseClientConfiguration {
            // Add your Parse applicationId:
            $0.applicationId = "your_application_id"
            // Uncomment and add your clientKey (it's not required if you are using Parse Server):
            $0.clientKey = "your_client_key"

            // Uncomment the following line and change to your Parse Server address;
            $0.server = "https://YOUR_PARSE_SERVER/parse"

            // Enable storing and querying data from Local Datastore.
            // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
            $0.isLocalDatastoreEnabled = true
        }
        Parse.initialize(with: configuration)

        PFUser.enableAutomaticUser()

        let defaultACL: PFACL = PFACL()
        // If you would like all objects to be private by default, remove this line.
        defaultACL.hasPublicReadAccess = true

        PFACL.setDefault(defaultACL, withAccessForCurrentUser: true)

        // ****************************************************************************
        // Uncomment these lines to register for Push Notifications.
        //
        // let types: NSRemoteNotificationType = [.alert, .badge, .sound]
        // NSApplication.shared().registerForRemoteNotifications(matching: types)
        //
        // ****************************************************************************

        PFAnalytics.trackAppOpened(launchOptions: nil)
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground()
        PFPush.subscribeToChannel(inBackground: "") { (succeeded: Bool, error: Error?) in
            if succeeded {
                print("ParseStarterProject successfully subscribed to push notifications on the broadcast channel.\n")
            } else {
                print("ParseStarterProject failed to subscribe to push notifications on the broadcast channel with error = %@.\n", error as Any)
            }
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("application:didFailToRegisterForRemoteNotificationsWithError: %@\n", error)
    }

    // ****************************************************************************
    // Uncomment these lines to track Push Notifications open rate in Analytics.
    //
    // func application(application: NSApplication, didReceiveRemoteNotification userInfo: [String : AnyObject]) {
    //   PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
    // }
}