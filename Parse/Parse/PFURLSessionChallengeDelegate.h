//
//  PFURLSessionChallengeDelegate.h
//  Parse
//
//  Created by Gytis Kvedaravicius (gytiskv) on 2019-11-30.
//  Copyright © 2019 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 An interface to handle URLSessionDelegate challenges
 */
@protocol PFURLSessionChallengeDelegate <NSObject>

/**
 This is default URLSessionDelegate method that gets called when a challenge is received.
 
 Read URLSessionDelegate for more details.
 */
-(void)URLSession:(NSURLSession *_Nullable)session
didReceiveChallenge:(NSURLAuthenticationChallenge *_Nullable)challenge
completionHandler:(void (^_Nonnull)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;

@end
