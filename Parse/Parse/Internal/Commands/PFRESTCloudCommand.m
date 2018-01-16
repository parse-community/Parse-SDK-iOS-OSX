/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCloudCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"

@implementation PFRESTCloudCommand

+ (instancetype)commandForFunction:(NSString *)function
                    withParameters:(NSDictionary *)parameters
                      sessionToken:(NSString *)sessionToken {
    NSString *path = [NSString stringWithFormat:@"functions/%@", function];
    return [self commandWithHTTPPath:path
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:parameters
                        sessionToken:sessionToken];
}

@end
