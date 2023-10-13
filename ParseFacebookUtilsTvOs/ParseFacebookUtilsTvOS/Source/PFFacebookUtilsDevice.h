//
//  Header.h
//  
//
//  Created by Volodymyr Nazarkevych on 29.11.2022.
//
@import ParseFacebookUtils;

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

@end
