//
//  PFAppleUtils.m
//  ParseUIDemo
//
//  Created by Darren Black on 20/12/2019.
//  Copyright © 2019 Parse Inc. All rights reserved.
//

#import "PFAppleUtils.h"
#import "PFAppleAuthenticationProvider.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <Bolts/Bolts.h>

NSString *const PFAppleUserAuthenticationType = @"apple";
NSString *const PFAppleAuthUserKey = @"user";
NSString *const PFAppleAuthCredentialKey = @"credential";

API_AVAILABLE(ios(13.0))
@interface PFAppleLoginManager ()

@property (strong, nonatomic) BFTask<PFUser *> *userTask;
@property (strong, nonatomic) BFTaskCompletionSource *completionSource;
@property (strong, nonatomic) PFAppleLoginManager *strongSelf;

@property (weak, nonatomic) ASAuthorizationController *controller;

@end

@implementation PFAppleLoginManager

-(BFTask<NSDictionary *> *) loginTaskWithController:(ASAuthorizationController *)controller {
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    
    self.userTask = source.task;
    controller.delegate = self;
    controller.presentationContextProvider = self;
    self.completionSource = source;
    self.strongSelf = self;
    self.controller = controller;
    
    return source.task;
}

- (nonnull ASPresentationAnchor)presentationAnchorForAuthorizationController:(nonnull ASAuthorizationController *)controller {
    return UIApplication.sharedApplication.keyWindow;
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization {
    ASAuthorizationAppleIDCredential *cred = authorization.credential;
    NSString *userId = cred.user;
    NSData *token = cred.identityToken;
    NSString *tokenString = [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding];
    
    __weak typeof(self) wself = self;
    
    [[[PFUser logInWithAuthTypeInBackground:PFAppleUserAuthenticationType
                                 authData:@{@"token" : tokenString, @"id" : userId}] continueWithSuccessBlock:^id _Nullable(BFTask<__kindof PFUser *> * _Nonnull t) {
        __strong typeof(wself) sself = wself;
        [sself.completionSource setResult:@{PFAppleAuthUserKey : t.result,
                                            PFAppleAuthCredentialKey : cred}];
        sself.strongSelf = nil;
        return t;
    }] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        __strong typeof(wself) sself = wself;
        if (t.error) {
            [sself.completionSource setError:t.error];
            sself.strongSelf = nil;
        }
        return nil;
    }];
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    [self.completionSource setError:error];
}

@end

@interface PFAppleUtils ()

@property (strong, nonatomic) PFAppleUtils *strongSelf;

@end

@implementation PFAppleUtils

static PFAppleAuthenticationProvider *_authenticationProvider;

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (!_authenticationProvider) {
            _authenticationProvider = [[PFAppleAuthenticationProvider alloc] init];
            [PFUser registerAuthenticationDelegate:_authenticationProvider forAuthType:PFAppleUserAuthenticationType];
        }
    }
    return self;
}

+ (BFTask<NSDictionary *> *)logInInBackground {
    PFAppleLoginManager *manager = [PFAppleLoginManager new];
    return  [PFAppleUtils logInInBackgroundWithManager:manager];
}

+ (BFTask<NSDictionary *> *)logInInBackgroundWithManager:(PFAppleLoginManager *)manager {
    if (!_authenticationProvider) {
        [PFAppleUtils new];
    }
    
    ASAuthorizationAppleIDProvider *provider = [ASAuthorizationAppleIDProvider new];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
    
    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    [controller performRequests];
    return [manager loginTaskWithController:controller];
}
@end

