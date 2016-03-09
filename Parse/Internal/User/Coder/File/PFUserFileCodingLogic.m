/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUserFileCodingLogic.h"

#import "PFDecoder.h"
#import "PFMutableUserState.h"
#import "PFObjectPrivate.h"
#import "PFUserConstants.h"
#import "PFUserPrivate.h"

@interface PFUserFileCodingLogic ()

@end

@implementation PFUserFileCodingLogic

///--------------------------------------
#pragma mark - Coding
///--------------------------------------

- (void)updateObject:(PFObject *)object fromDictionary:(NSDictionary *)dictionary usingDecoder:(PFDecoder *)decoder {
    PFUser *user = (PFUser *)object;

    NSString *newSessionToken = dictionary[@"session_token"] ?: dictionary[PFUserSessionTokenRESTKey];
    if (newSessionToken) {
        user._state = [(PFUserState *)user._state copyByMutatingWithBlock:^(PFMutableUserState *state) {
            state.sessionToken = newSessionToken;
        }];
    }

    // Merge the linked service metadata
    NSDictionary *newAuthData = dictionary[@"auth_data"] ?: dictionary[PFUserAuthDataRESTKey];
    newAuthData = [decoder decodeObject:newAuthData];
    if (newAuthData) {
        [user.authData removeAllObjects];
        [user.linkedServiceNames removeAllObjects];
        [newAuthData enumerateKeysAndObjectsUsingBlock:^(id key, id linkData, BOOL *stop) {
            if (linkData != [NSNull null]) {
                user.authData[key] = linkData;
                [user.linkedServiceNames addObject:key];
                [user synchronizeAuthDataWithAuthType:key];
            } else {
                [user.authData removeObjectForKey:key];
                [user.linkedServiceNames removeObject:key];
                [user synchronizeAuthDataWithAuthType:key];
            }
        }];
    }

    [super updateObject:user fromDictionary:dictionary usingDecoder:decoder];
}

@end
