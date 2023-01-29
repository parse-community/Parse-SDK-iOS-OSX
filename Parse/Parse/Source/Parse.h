/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "ParseClientConfiguration.h"
#import "PFACL.h"
#import "PFAnalytics.h"
#import "PFAnonymousUtils.h"
#import "PFAnonymousUtils+Deprecated.h"
#import "PFCloud.h"
#import "PFCloud+Deprecated.h"
#import "PFCloud+Synchronous.h"
#import "PFConfig.h"
#import "PFConfig+Synchronous.h"
#import "PFConstants.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFFileObject.h"
#import "PFFileObject+Deprecated.h"
#import "PFFileObject+Synchronous.h"
#import "PFGeoPoint.h"
#import "PFPolygon.h"
#import "PFObject.h"
#import "PFObject+Subclass.h"
#import "PFObject+Synchronous.h"
#import "PFObject+Deprecated.h"
#import "PFQuery.h"
#import "PFQuery+Synchronous.h"
#import "PFQuery+Deprecated.h"
#import "PFRelation.h"
#import "PFRole.h"
#import "PFSession.h"
#import "PFSubclassing.h"
#import "PFUser.h"
#import "PFUser+Synchronous.h"
#import "PFUser+Deprecated.h"
#import "PFUserAuthenticationDelegate.h"
#import "PFFileUploadResult.h"
#import "PFFileUploadController.h"

#if TARGET_OS_IOS

#import "PFInstallation.h"
#import "PFNetworkActivityIndicatorManager.h"
#import "PFPush.h"
#import "PFPush+Synchronous.h"
#import "PFPush+Deprecated.h"
#import "PFProduct.h"
#import "PFPurchase.h"

#elif PF_TARGET_OS_OSX

#import "PFInstallation.h"
#import "PFPush.h"
#import "PFPush+Synchronous.h"
#import "PFPush+Deprecated.h"

#elif TARGET_OS_TV

#import "PFInstallation.h"
#import "PFPush.h"
#import "PFProduct.h"
#import "PFPurchase.h"

#endif

NS_ASSUME_NONNULL_BEGIN

/**
 The `Parse` class contains static functions that handle global configuration for the Parse framework.
 */
@interface Parse : NSObject

///--------------------------------------
#pragma mark - Connecting to Parse
///--------------------------------------

/**
 Sets the applicationId and clientKey of your application.

 @param applicationId The application id of your Parse application.
 @param clientKey The client key of your Parse application.
 */
+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

/**
 Sets the configuration to be used for the Parse SDK.

 @note Re-setting the configuration after having previously sent requests through the SDK results in undefined behavior.

 @param configuration The new configuration to set for the SDK.
 */
+ (void)initializeWithConfiguration:(ParseClientConfiguration *)configuration;

/**
 Gets the current configuration in use by the Parse SDK.

 @return The current configuration in use by the SDK. Returns nil if the SDK has not been initialized yet.
 */
@property (nonatomic, nullable, readonly, class) ParseClientConfiguration *currentConfiguration;

/**
 Sets the server URL to connect to Parse Server. The local client cache is not cleared.
 @discussion This can be used to update the server URL after this client has been initialized, without having to destroy this client. An example use case is
 server connection failover, where the clients connects to another URL if the server becomes unreachable at the current URL.
 @warning The new server URL must point to a Parse Server that connects to the same database. Otherwise, issues may arise
 related to locally cached data or delayed methods such as saveEventually.
 @param server  The server URL to set.
 */
+ (void)setServer:(nonnull NSString *)server;

/**
 The current application id that was used to configure Parse framework.
 */
@property (nonatomic, nonnull, readonly, class) NSString *applicationId;

+ (NSString *)getApplicationId PARSE_DEPRECATED("Use applicationId property.");

/**
 The current client key that was used to configure Parse framework.
 */
@property (nonatomic, nullable, readonly, class) NSString *clientKey;

+ (nullable NSString *)getClientKey PARSE_DEPRECATED("Use clientKey property.");

/**
 The current server URL to connect to Parse Server.
 */
@property (nonatomic, nullable, readonly, class) NSString *server;

///--------------------------------------
#pragma mark - Enabling Local Datastore
///--------------------------------------

/**
 Enable pinning in your application. This must be called before your application can use
 pinning. The recommended way is to call this method before `+setApplicationId:clientKey:`.
 */
+ (void)enableLocalDatastore PF_TV_UNAVAILABLE;

/**
 Flag that indicates whether Local Datastore is enabled.
 
 @return `YES` if Local Datastore is enabled, otherwise `NO`.
 */
@property (nonatomic, readonly, class) BOOL isLocalDatastoreEnabled PF_TV_UNAVAILABLE;

///--------------------------------------
#pragma mark - Enabling Extensions Data Sharing
///--------------------------------------

/**
 Enables data sharing with an application group identifier.

 After enabling - Local Datastore, `PFUser.+currentUser`, `PFInstallation.+currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before `+setApplicationId:clientKey:`.

 @param groupIdentifier Application Group Identifier to share data with.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier PF_EXTENSION_UNAVAILABLE("Use `enableDataSharingWithApplicationGroupIdentifier:containingApplication:`.") PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Enables data sharing with an application group identifier.

 After enabling - Local Datastore, `PFUser.+currentUser`, `PFInstallation.+currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before `+setApplicationId:clientKey:`.
 This method can only be used by application extensions.

 @param groupIdentifier Application Group Identifier to share data with.
 @param bundleIdentifier Bundle identifier of the containing application.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier
                                  containingApplication:(NSString *)bundleIdentifier PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Application Group Identifier for Data Sharing.

 @return `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)applicationGroupIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Containing application bundle identifier for Data Sharing.

 @return `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)containingApplicationBundleIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

#if TARGET_OS_IOS

///--------------------------------------
#pragma mark - Configuring UI Settings
///--------------------------------------

/**
 Set whether to show offline messages when using a Parse view or view controller related classes.

 @param enabled Whether a `UIAlertView` should be shown when the device is offline
 and network access is required from a view or view controller.

 @deprecated This method has no effect.
 */
+ (void)offlineMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

/**
 Set whether to show an error message when using a Parse view or view controller related classes
 and a Parse error was generated via a query.

 @param enabled Whether a `UIAlertView` should be shown when an error occurs.

 @deprecated This method has no effect.
 */
+ (void)errorMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

#endif

///--------------------------------------
#pragma mark - Logging
///--------------------------------------

/**
 Gets or sets the level of logging to display.

 By default:
 - If running inside an app that was downloaded from iOS App Store - it is set to `PFLogLevelNone`
 - All other cases - it is set to `PFLogLevelWarning`

 @return A `PFLogLevel` value.
 @see PFLogLevel
 */
@property (nonatomic, readwrite, class) PFLogLevel logLevel;

@end

///--------------------------------------
#pragma mark - Notifications
///--------------------------------------

/**
 For testing purposes. Allows testers to know when init is complete.
 */
extern NSString *const _Nonnull PFParseInitializeDidCompleteNotification;

NS_ASSUME_NONNULL_END
