//
//  Header.h
//
//
//  Created by Volodymyr Nazarkevych on 29.11.2022.
//

#import <Foundation/Foundation.h>

#if __has_include(<ParseFacebookUtilsV4/PFFacebookUtils.h>)
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#else
#import "PFFacebookUtils.h"
#endif

#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface PFFacebookUtilsDevice : PFFacebookUtils

///--------------------------------------
/// @name Interacting With Facebook
///--------------------------------------

/**
 Initializes Parse Facebook Utils.

 You must provide your Facebook application ID as the value for FacebookAppID in your bundle's plist file
 as described here: https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/

 @warning You must invoke this in order to use the Facebook functionality in Parse.

 @param launchOptions The launchOptions as passed to [UIApplicationDelegate application:didFinishLaunchingWithOptions:].
 */
+ (void)initializeFacebookWithApplicationLaunchOptions:(nullable NSDictionary *)launchOptions;

/**
 `FBSDKLoginManager` provides methods for configuring login behavior, default audience
 and managing Facebook Access Token.
 
 @warning This method is available only on iOS.

 @return An instance of `FBSDKLoginManager` that is used by `PFFacebookUtils`.
 */
+ ( FBSDKLoginManager * _Nonnull)facebookLoginManager;

@end
