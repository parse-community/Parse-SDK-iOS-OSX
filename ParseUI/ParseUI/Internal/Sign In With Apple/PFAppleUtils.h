//
//  PFAppleUtils.h
//  ParseUIDemo
//
//  Created by Darren Black on 20/12/2019.
//  Copyright © 2019 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Parse/PFConstants.h>)
#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>
#else
#import "PFConstants.h"
#import "PFUser.h"
#endif

@import AuthenticationServices;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PFAppleUserAuthenticationType;
extern NSString *const PFAppleAuthUserKey;
extern NSString *const PFAppleAuthCredentialKey;

API_AVAILABLE(ios(13.0))
@interface PFAppleLoginManager : NSObject <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@end

API_AVAILABLE(ios(13.0))
@interface PFAppleUtils : NSObject

+ (BFTask<NSDictionary *> *)logInInBackground;

@end

NS_ASSUME_NONNULL_END
