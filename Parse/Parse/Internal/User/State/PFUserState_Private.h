/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUserState.h"

@interface PFUserState () {
@protected
    NSString *_sessionToken;
    NSDictionary *_authData;

    BOOL _isNew;
}

@property (nonatomic, copy, readwrite) NSString *sessionToken;
@property (nonatomic, copy, readwrite) NSDictionary *authData;

@property (nonatomic, assign, readwrite) BOOL isNew;

@end
