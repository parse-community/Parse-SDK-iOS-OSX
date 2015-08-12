/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTFileCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"

@implementation PFRESTFileCommand

+ (instancetype)uploadCommandForFileWithName:(NSString *)fileName
                                sessionToken:(NSString *)sessionToken {
    NSMutableString *httpPath = [@"files/" mutableCopy];
    if (fileName) {
        [httpPath appendString:fileName];
    }
    return [self commandWithHTTPPath:httpPath
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:nil
                        sessionToken:sessionToken];
}

@end
