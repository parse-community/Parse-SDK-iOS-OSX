/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PF_Twitter.h"

@class ACAccount;
@class ACAccountStore;
@protocol PFOAuth1FlowDialogInterface;

NS_ASSUME_NONNULL_BEGIN

@interface PF_Twitter ()

@property (nonatomic, strong, readonly) ACAccountStore *accountStore;
@property (nonatomic, strong, readonly) NSURLSession *urlSession;
@property (nonatomic, strong, readonly) Class<PFOAuth1FlowDialogInterface> oauthDialogClass;

- (instancetype)initWithAccountStore:(ACAccountStore *)accountStore
                          urlSession:(NSURLSession *)urlSession
                         dialogClass:(Class<PFOAuth1FlowDialogInterface>)dialogClass;

/**
 Obtain access to the local twitter account.
 Returns the twitter account if access is obtained. Otherwise, returns null.
 */
- (BFTask<ACAccount *> *)_getLocalTwitterAccountAsync;

@end

NS_ASSUME_NONNULL_END
