/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTConfigCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"

@implementation PFRESTConfigCommand

+ (instancetype)configFetchCommandWithSessionToken:(NSString *)sessionToken {
    return [self commandWithHTTPPath:@"config"
                          httpMethod:PFHTTPRequestMethodGET
                          parameters:nil
                        sessionToken:sessionToken
                               error:nil];
}

+ (instancetype)configUpdateCommandWithConfigParameters:(NSDictionary *)parameters
                                           sessionToken:(NSString *)sessionToken {
    NSDictionary *commandParameters = @{ @"params" : parameters };
    return [self commandWithHTTPPath:@"config"
                          httpMethod:PFHTTPRequestMethodPUT
                          parameters:commandParameters
                        sessionToken:sessionToken
                               error:nil];
}

@end
