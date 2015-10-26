/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFACL.h"
#import "PFAnalytics.h"
#import "PFAnonymousUtils.h"
#import "PFCloud.h"
#import "PFConfig.h"
#import "PFConstants.h"
#import "PFFile.h"
#import "PFGeoPoint.h"
#import "PFObject+Subclass.h"
#import "PFObject.h"
#import "PFQuery.h"
#import "PFRelation.h"
#import "PFRole.h"
#import "PFSession.h"
#import "PFSubclassing.h"
#import "PFUser.h"
#import "PFUserAuthenticationDelegate.h"
#import "PFNullability.h"

#if TARGET_OS_IOS

#import "PFInstallation.h"
#import "PFNetworkActivityIndicatorManager.h"
#import "PFPush.h"
#import "PFProduct.h"
#import "PFPurchase.h"

#elif PF_TARGET_OS_OSX

#import "PFInstallation.h"
#import "PFPush.h"

#elif TARGET_OS_TV

#import "PFProduct.h"
#import "PFPurchase.h"

#endif

PF_ASSUME_NONNULL_BEGIN

/*!
 The `Parse` class contains static functions that handle global configuration for the Parse framework.
 */
@interface Parse : NSObject

///--------------------------------------
/// @name Connecting to Parse
///--------------------------------------

/*!
 @abstract Sets the applicationId and clientKey of your application.

 @param applicationId The application id of your Parse application.
 @param clientKey The client key of your Parse application.
 */
+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

/*!
 @abstract The current application id that was used to configure Parse framework.
 */
+ (NSString *)getApplicationId;

/*!
 @abstract The current client key that was used to configure Parse framework.
 */
+ (NSString *)getClientKey;

///--------------------------------------
/// @name Enabling Local Datastore
///--------------------------------------

/*!
 @abstract Enable pinning in your application. This must be called before your application can use
 pinning. The recommended way is to call this method before `setApplicationId:clientKey:`.
 */
+ (void)enableLocalDatastore;

/*!
 @abstract Flag that indicates whether Local Datastore is enabled.

 @returns `YES` if Local Datastore is enabled, otherwise `NO`.
 */
+ (BOOL)isLocalDatastoreEnabled;

///--------------------------------------
/// @name Enabling Extensions Data Sharing
///--------------------------------------

/*!
 @abstract Enables data sharing with an application group identifier.

 @discussion After enabling - Local Datastore, `currentUser`, `currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before <setApplicationId:clientKey:>.

 @param groupIdentifier Application Group Identifier to share data with.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier PF_EXTENSION_UNAVAILABLE("Use `enableDataSharingWithApplicationGroupIdentifier:containingApplication:`.") PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/*!
 @abstract Enables data sharing with an application group identifier.

 @discussion After enabling - Local Datastore, `currentUser`, `currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before <setApplicationId:clientKey:>.
 This method can only be used by application extensions.

 @param groupIdentifier Application Group Identifier to share data with.
 @param bundleIdentifier Bundle identifier of the containing application.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier
                                  containingApplication:(NSString *)bundleIdentifier PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/*!
 @abstract Application Group Identifier for Data Sharing

 @returns `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)applicationGroupIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/*!
 @abstract Containing application bundle identifier.

 @returns `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)containingApplicationBundleIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

#if PARSE_IOS_ONLY

///--------------------------------------
/// @name Configuring UI Settings
///--------------------------------------

/*!
 @abstract Set whether to show offline messages when using a Parse view or view controller related classes.

 @param enabled Whether a `UIAlertView` should be shown when the device is offline
 and network access is required from a view or view controller.

 @deprecated This method has no effect.
 */
+ (void)offlineMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

/*!
 @abstract Set whether to show an error message when using a Parse view or view controller related classes
 and a Parse error was generated via a query.

 @param enabled Whether a `UIAlertView` should be shown when an error occurs.

 @deprecated This method has no effect.
 */
+ (void)errorMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

#endif

///--------------------------------------
/// @name Logging
///--------------------------------------

/*!
 @abstract Sets the level of logging to display.

 @discussion By default:
 - If running inside an app that was downloaded from iOS App Store - it is set to <PFLogLevelNone>
 - All other cases - it is set to <PFLogLevelWarning>

 @param logLevel Log level to set.
 @see PFLogLevel
 */
+ (void)setLogLevel:(PFLogLevel)logLevel;

/*!
 @abstract Log level that will be displayed.

 @discussion By default:
 - If running inside an app that was downloaded from iOS App Store - it is set to <PFLogLevelNone>
 - All other cases - it is set to <PFLogLevelWarning>

 @returns A <PFLogLevel> value.
 @see PFLogLevel
 */
+ (PFLogLevel)logLevel;

@end

PF_ASSUME_NONNULL_END
