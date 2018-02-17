/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PF_Twitter.h"
#import "PF_Twitter_Private.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <Twitter/Twitter.h>

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import <Parse/PFConstants.h>

#import "PFOAuth1FlowDialog.h"
#import "PFTwitterAlertView.h"
#import "PFTwitterPrivateUtilities.h"
#import "PF_OAuthCore.h"
#import "PFTwitterLocalization.h"

@implementation PF_Twitter

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    return [self initWithAccountStore:[[ACAccountStore alloc] init]
                           urlSession:[NSURLSession sharedSession]
                          dialogClass:[PFOAuth1FlowDialog class]];
}

- (instancetype)initWithAccountStore:(ACAccountStore *)accountStore
                          urlSession:(NSURLSession *)urlSession
                         dialogClass:(Class<PFOAuth1FlowDialogInterface>)dialogClass {
    self = [super init];
    if (!self) return nil;

    _accountStore = accountStore;
    _urlSession = urlSession;
    _oauthDialogClass = dialogClass;

    PFTWConsistencyAssert(_oauthDialogClass == nil ||
                          [(id)_oauthDialogClass conformsToProtocol:@protocol(PFOAuth1FlowDialogInterface)],
                          @"OAuth Dialog class must conform to the Dialog Interface protocol!");

    return self;
}

///--------------------------------------
#pragma mark - Authorize
///--------------------------------------

- (BFTask *)authorizeInBackground {
    if (self.consumerKey.length == 0 || self.consumerSecret.length == 0) {
        //TODO: (nlutsenko) This doesn't look right, maybe we should add additional error code?
        return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain code:1 userInfo:nil]];
    }

    return [[self _performReverseAuthAsync] pftw_continueAsyncWithBlock:^id(BFTask *task) {
        BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
        dispatch_async(dispatch_get_main_queue(), ^{
            // if reverse auth was successful then return
            if (task.cancelled) {
                [source cancel];
                return;
            } else if (!task.error && !task.result) {
                source.result = nil;
                return;
            }

            // fallback to the webview auth
            [[self _performWebViewAuthAsync] pftw_continueAsyncWithBlock:^id(BFTask *task) {
                NSError *error = task.error;
                if (task.cancelled) {
                    [source cancel];
                } else if (!error) {
                    [source setResult:task.result];
                } else {
                    [source setError:error];
                }
                return nil;
            }];
        });
        return source.task;
    }];
}
- (BFTask *)deauthorizeInBackground {
    if (self.consumerKey.length == 0 || self.consumerSecret.length == 0) {
        //TODO: (nlutsenko) This doesn't look right, maybe we should add additional error code?
        return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain code:1 userInfo:nil]];
    }

    return [[self _performDeauthAsync] pftw_continueAsyncWithBlock:^id(BFTask *task) {
        BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
        if (task.cancelled) {
            [source cancel];
        } else if (!task.error && !task.result) {
            source.result = nil;
        } else if (task.error) {
            [source trySetError:task.error];
        } else if (task.result) {
            [self setLoginResultValues:nil];

            [source trySetResult:task.result];
        }
        return source.task;
    }];
}

- (void)authorizeWithSuccess:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure
                      cancel:(void (^)(void))cancel {
    [[self authorizeInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                             withBlock:^id(BFTask *task) {
                                                 if (task.error) {
                                                     failure(task.error);
                                                 } else if (task.cancelled) {
                                                     cancel();
                                                 } else {
                                                     success();
                                                 }
                                                 return nil;
                                             }];
}

// Displays the web view dialog
- (BFTask *)_showWebViewDialogAsync:(NSString *)requestToken requestSecret:(NSString *)requestSecret {
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

    static NSString *twitterAuthURLString = @"https://api.twitter.com/oauth/authenticate";

    PFOAuth1FlowDialog *dialog = [_oauthDialogClass dialogWithURL:[NSURL URLWithString:twitterAuthURLString]
                                                  queryParameters:@{ @"oauth_token" : requestToken }];
    dialog.redirectURLPrefix = @"http://twitter-oauth.callback";
    dialog.completion = ^(BOOL succeeded, NSURL *url, NSError *error) {
        // In case of error
        if (error) {
            source.error = error;
            return;
        }
        // In case the dialog was cancelled
        if (!succeeded) {
            [source cancel];
            return;
        }

        // Handle URL received.
        NSDictionary *authQueryParams = [NSURL PF_ab_parseURLQueryString:[url query]];
        NSString *verifier = [authQueryParams objectForKey:@"oauth_verifier"];
        NSString *token = [authQueryParams objectForKey:@"oauth_token"];

        [[self _getAccessTokenForWebAuthAsync:verifier requestSecret:requestSecret token:token]
         pftw_continueAsyncWithBlock:^id (BFTask *task) {
             NSError *error = task.error;
             if (!error) {
                 NSDictionary *accessResult = (NSDictionary*) task.result;
                 [self setLoginResultValues:accessResult];
                 source.result = nil;
             } else {
                 source.error = error;
             }
             return nil;
         }];
    };
    [dialog showAnimated:YES];

    return source.task;
}

/**
 Get the request token for the authentication. This is the first step in auth.
 if isReverseAuth is YES then get the request token for reverse auth mode. Otherwise, get the request token for web auth mode.
 */
- (BFTask *)_getRequestTokenAsync:(BOOL)isReverseAuth {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    NSMutableDictionary *params = nil;
    NSData *body = nil;

    if (isReverseAuth) {
        body = [[NSString stringWithFormat:@"x_auth_mode=%@", @"reverse_auth"] dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        params = [NSMutableDictionary dictionary];
        [params setObject:@"http://twitter-oauth.callback" forKey:@"oauth_callback"];
    }

    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:url
                                                                             method:@"POST"
                                                                               body:body
                                                               additionalParameters:params
                                                                        consumerKey:_consumerKey
                                                                     consumerSecret:_consumerSecret
                                                                              token:nil
                                                                        tokenSecret:nil];
    NSString *header = [PFOAuth authorizationHeaderFromConfiguration:configuration];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:header forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:body];

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [taskCompletionSource trySetError:error];
        } else {
            [taskCompletionSource trySetResult:data];
        }
    }] resume];
    return taskCompletionSource.task;
}

// Get the access token for web authentication
- (BFTask *)_getAccessTokenForWebAuthAsync:(NSString *)verifier
                             requestSecret:(NSString *)requestSecret
                                     token:(NSString *)token {
    NSURL *accessTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSData *body = [[NSString stringWithFormat:@"oauth_verifier=%@", verifier] dataUsingEncoding:NSUTF8StringEncoding];
    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:accessTokenURL
                                                                             method:@"POST"
                                                                               body:body
                                                               additionalParameters:nil
                                                                        consumerKey:_consumerKey
                                                                     consumerSecret:_consumerSecret
                                                                              token:token
                                                                        tokenSecret:requestSecret];
    NSString *accessTokenHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];
    NSMutableURLRequest *accessRequest = [NSMutableURLRequest requestWithURL:accessTokenURL];
    [accessRequest setHTTPMethod:@"POST"];
    [accessRequest addValue:accessTokenHeader forHTTPHeaderField:@"Authorization"];
    [accessRequest setHTTPBody:body];

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [[self.urlSession dataTaskWithRequest:accessRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [taskCompletionSource trySetError:error];
        } else {
            NSString *accessResponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *accessResponseValues = [NSURL PF_ab_parseURLQueryString:accessResponseString];
            [taskCompletionSource trySetResult:accessResponseValues];
        }
    }] resume];
    return taskCompletionSource.task;
}

/**
 Get the access token for reverse authentication.
 If the Task is successful then, Task result is dictionary containing logged in user's Auth token, Screenname and other attributes.
 */
- (BFTask *)_getAccessTokenForReverseAuthAsync:(NSString *)signedReverseAuthSignature
                           localTwitterAccount:(ACAccount *)localTwitterAccount {

    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    if (!signedReverseAuthSignature ||
        [signedReverseAuthSignature length] == 0 ||
        !localTwitterAccount) {

        source.error = [NSError errorWithDomain:PFParseErrorDomain code:1 userInfo:nil];
        return source.task;
    }

    NSDictionary *params = @{ @"x_reverse_auth_parameters" : signedReverseAuthSignature,
                              @"x_reverse_auth_target" : _consumerKey };

    NSURL *accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    SLRequest *accessRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                  requestMethod:SLRequestMethodPOST
                                                            URL:accessTokenUrl
                                                     parameters:params];

    [accessRequest setAccount:localTwitterAccount];
    [accessRequest performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error) {
            [source setError:error];
        } else {
            NSString *accessResponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *accessResponseValues = [NSURL PF_ab_parseURLQueryString:accessResponseString];
            [source setResult:accessResponseValues];
        }
    }];

    return source.task;
}

// Set the result parameters from the data returned om succesful login
- (void)setLoginResultValues:(NSDictionary *)resultData {
    self.authToken = [resultData objectForKey:@"oauth_token"];
    self.authTokenSecret = [resultData objectForKey:@"oauth_token_secret"];
    self.userId = [resultData objectForKey:@"user_id"];
    self.screenName = [resultData objectForKey:@"screen_name"];
}

// Performs the Reverse auth for the the twitter account setup on the device.
- (BFTask *)_performReverseAuthAsync {
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

    // get permission to access the account if its setup and available.
    [[self _getLocalTwitterAccountAsync] pftw_continueAsyncWithBlock:^id(BFTask *task) {

        if (task.error) {
            source.error = task.error;
            return source.task;
        }

        if (task.cancelled) {
            [source cancel];
            return source.task;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            ACAccount *localTwitterAccount = (ACAccount*) task.result;

            if(!localTwitterAccount) {
                source.error = [NSError errorWithDomain:PFParseErrorDomain code:2 userInfo:nil];
                return;
            }

            // continue with reverse auth since its permitted
            [[self _getRequestTokenAsync:YES] pftw_continueAsyncWithBlock:^id(BFTask *task) {
                if (task.error) {
                    source.error = task.error;
                    return source.task;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *requestTokenResponse = [[NSString alloc] initWithData:task.result encoding:NSUTF8StringEncoding];

                    [[self _getAccessTokenForReverseAuthAsync:requestTokenResponse
                                          localTwitterAccount:localTwitterAccount] pftw_continueAsyncWithBlock:^id(BFTask *task) {
                        NSError *error = task.error;
                        if (!error) {
                            NSDictionary *accessResult = (NSDictionary*) task.result;
                            [self setLoginResultValues:accessResult];
                            source.result = nil;
                        } else {
                            source.error = task.error;
                        }
                        return nil;
                    }];
                });
                return nil;
            }];

        });
        return nil;
    }];

    return source.task;
}

- (BFTask *)_performWebViewAuthAsync {
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

    [[self _getRequestTokenAsync:NO] pftw_continueAsyncWithBlock:^id(BFTask *task) {
        if (task.error || task.isCancelled) {
            if (task.error) {
                [source setError:task.error];
            } else {
                [source cancel];
            }
            return task;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *requestTokenResponse = [[NSString alloc] initWithData:task.result encoding:NSUTF8StringEncoding];

            NSDictionary *requestTokenParsed = [NSURL PF_ab_parseURLQueryString:requestTokenResponse];
            NSString *requestToken = requestTokenParsed[@"oauth_token"];
            NSString *requestSecret = requestTokenParsed[@"oauth_token_secret"];

            // If one of these is missing, then we failed to get a token.
            if (!requestToken || !requestSecret) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Failed to request authorization token from Twitter." };
                NSError *error = [NSError errorWithDomain:PFParseErrorDomain code:2 userInfo:userInfo];
                [source setError:error];
                return;
            }

            // show the webview dialog for auth token
            [[self _showWebViewDialogAsync:requestToken
                             requestSecret:requestSecret] pftw_continueAsyncWithBlock:^id(BFTask *task) {
                NSError *error = task.error;
                if (task.isCancelled) {
                    [source cancel];
                } else if (!error) {
                    [source setResult:task.result];
                } else {
                    [source setError:error];
                }
                return nil;
            }];
        });
        return nil;
    }];

    return source.task;
}

- (BFTask<ACAccount *> *)_getLocalTwitterAccountAsync {
    BFTaskCompletionSource<ACAccount *> *source = [BFTaskCompletionSource taskCompletionSource];

    // If no twitter accounts present in the system, then no need to ask for permission to the user
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [source setResult:nil];
        return source.task;
    }

    ACAccountType *twitterType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [_accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if (error) {
            [source setError:error];
            return;
        }

        if (!granted) {
            [source setResult:nil];
            return;
        }

        NSArray *accounts = [self->_accountStore accountsWithAccountType:twitterType];

        // No accounts - provide an empty result
        if ([accounts count] == 0) {
            [source setResult:nil];
            return;
        }

        // Finish if there is only 1 account
        if ([accounts count] == 1) {
            [source setResult:accounts[0]];
            return;
        }

        NSArray *usernames = [accounts valueForKey:@"accountDescription"];

        // Call async on the main thread, as the completion isn't executed on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [PFTwitterAlertView showAlertWithTitle:PFTWLocalizedString(@"Select a Twitter Account", @"Select a Twitter Account")
                                           message:nil
                                 cancelButtonTitle:PFTWLocalizedString(@"Cancel", @"Cancel")
                                 otherButtonTitles:usernames
                                        completion:^(NSUInteger buttonIndex) {
                                            if (buttonIndex == NSNotFound) {
                                                [source cancel];
                                            } else {
                                                ACAccount *account = accounts[buttonIndex];
                                                [source setResult:account];
                                            }
                                        }];
        });
    }];

    return source.task;
}

- (BFTask *)_performDeauthAsync {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = [NSURL URLWithString:@"https://api.twitter.com/oauth2/invalidate_token"];
    request.HTTPMethod = @"POST";

    [self signRequest:request];

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];

    [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [taskCompletionSource trySetError:error];
        } else {
            [taskCompletionSource trySetResult:data];
        }
    }] resume];

    return taskCompletionSource.task;
}

///--------------------------------------
#pragma mark - Sign Request
///--------------------------------------

- (void)signRequest:(NSMutableURLRequest *)request {
    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:request.URL
                                                                             method:request.HTTPMethod ?: @"GET"
                                                                               body:request.HTTPBody
                                                               additionalParameters:nil
                                                                        consumerKey:_consumerKey
                                                                     consumerSecret:_consumerSecret
                                                                              token:_authToken
                                                                        tokenSecret:_authTokenSecret];
    NSString *header = [PFOAuth authorizationHeaderFromConfiguration:configuration];
    [request addValue:header forHTTPHeaderField:@"Authorization"];
}

@end
