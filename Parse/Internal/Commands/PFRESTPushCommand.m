/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTPushCommand.h"

#import "PFAssert.h"
#import "PFDateFormatter.h"
#import "PFHTTPRequest.h"
#import "PFInternalUtils.h"
#import "PFPushState.h"
#import "PFQueryState.h"
#import "PFRESTQueryCommand.h"

@implementation PFRESTPushCommand

+ (instancetype)sendPushCommandWithPushState:(PFPushState *)state
                                sessionToken:(NSString *)sessionToken {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (state.queryState) {
        NSDictionary *queryParameters = [PFRESTQueryCommand findCommandParametersForQueryState:state.queryState];
        parameters[@"where"] = queryParameters[@"where"];
    } else {
        if (state.channels) {
            parameters[@"channels"] = state.channels.allObjects;
        }
    }

    // If there are no conditions set, then push to everyone by specifying empty query conditions.
    if (parameters.count == 0) {
        parameters[@"where"] = @{};
    }

    if (state.expirationDate) {
        parameters[@"expiration_time"] = [[PFDateFormatter sharedFormatter] preciseStringFromDate:state.expirationDate];
    } else if (state.expirationTimeInterval) {
        parameters[@"expiration_interval"] = state.expirationTimeInterval;
    }

    if (state.pushDate) {
        parameters[@"push_time"] = [[PFDateFormatter sharedFormatter] preciseStringFromDate:state.pushDate];
    }

    // TODO (nlutsenko): Probably we need an assert here, as there is no reason to send push without message
    if (state.payload) {
        parameters[@"data"] = state.payload;
    }

    return [self commandWithHTTPPath:@"push"
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:parameters
                        sessionToken:sessionToken];
}

@end
