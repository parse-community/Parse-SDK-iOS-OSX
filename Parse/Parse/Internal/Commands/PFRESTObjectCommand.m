/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTObjectCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"
#import "PFObjectState.h"

@implementation PFRESTObjectCommand

+ (instancetype)fetchObjectCommandForObjectState:(PFObjectState *)state
                                withSessionToken:(NSString *)sessionToken {
    PFParameterAssert(state.objectId.length, @"objectId should be non nil");
    PFParameterAssert(state.parseClassName.length, @"Class name should be non nil");

    NSString *httpPath = [NSString stringWithFormat:@"classes/%@/%@", state.parseClassName, state.objectId];
    PFRESTObjectCommand *command = [self commandWithHTTPPath:httpPath
                                                  httpMethod:PFHTTPRequestMethodGET
                                                  parameters:nil
                                                sessionToken:sessionToken
                                                       error:nil];
    return command;
}

+ (instancetype)createObjectCommandForObjectState:(PFObjectState *)state
                                          changes:(NSDictionary *)changes
                                 operationSetUUID:(NSString *)operationSetIdentifier
                                     sessionToken:(NSString *)sessionToken {
    PFParameterAssert(state.parseClassName.length, @"Class name should be non nil");

    NSString *httpPath = [NSString stringWithFormat:@"classes/%@", state.parseClassName];
    PFRESTObjectCommand *command = [self commandWithHTTPPath:httpPath
                                                  httpMethod:PFHTTPRequestMethodPOST
                                                  parameters:changes
                                            operationSetUUID:operationSetIdentifier
                                                sessionToken:sessionToken
                                                       error:nil];
    return command;
}

+ (instancetype)updateObjectCommandForObjectState:(PFObjectState *)state
                                          changes:(NSDictionary *)changes
                                 operationSetUUID:(NSString *)operationSetIdentifier
                                     sessionToken:(NSString *)sessionToken {
    PFParameterAssert(state.parseClassName.length, @"Class name should be non nil");
    PFParameterAssert(state.objectId.length, @"objectId should be non nil");

    NSString *httpPath = [NSString stringWithFormat:@"classes/%@/%@", state.parseClassName, state.objectId];
    PFRESTObjectCommand *command = [self commandWithHTTPPath:httpPath
                                                  httpMethod:PFHTTPRequestMethodPUT
                                                  parameters:changes
                                            operationSetUUID:operationSetIdentifier
                                                sessionToken:sessionToken
                                                       error:nil];
    return command;
}

+ (instancetype)deleteObjectCommandForObjectState:(PFObjectState *)state
                                 withSessionToken:(NSString *)sessionToken {
    PFParameterAssert(state.parseClassName.length, @"Class name should be non nil");

    NSMutableString *httpPath = [NSMutableString stringWithFormat:@"classes/%@", state.parseClassName];
    if (state.objectId) {
        [httpPath appendFormat:@"/%@", state.objectId];
    }
    PFRESTObjectCommand *command = [self commandWithHTTPPath:httpPath
                                                  httpMethod:PFHTTPRequestMethodDELETE
                                                  parameters:nil
                                                sessionToken:sessionToken
                                                       error:nil];
    return command;
}

@end
