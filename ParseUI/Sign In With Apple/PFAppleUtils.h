//
//  PFAppleUtils.h
//  ParseUIDemo
//
//  Created by Darren Black on 20/12/2019.
//  Copyright © 2019 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>
@import AuthenticationServices;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PFAppleUserAuthenticationType;

API_AVAILABLE(ios(13.0))
@interface PFAppleLoginManager : NSObject <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@end

API_AVAILABLE(ios(13.0))
@interface PFAppleUtils : NSObject

+ (BFTask<NSDictionary *> *)logInInBackground;

@end

NS_ASSUME_NONNULL_END
