/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTObjectBatchCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"
#import "PFURLConstructor.h"

NSUInteger const PFRESTObjectBatchCommandSubcommandsLimit = 50;

@implementation PFRESTObjectBatchCommand

+ (nonnull instancetype)batchCommandWithCommands:(nonnull NSArray<PFRESTCommand *> *)commands
                                    sessionToken:(nullable NSString *)sessionToken
                                       serverURL:(nonnull NSURL *)serverURL {
    PFParameterAssert(commands.count <= PFRESTObjectBatchCommandSubcommandsLimit,
                      @"Max of %d commands are allowed in a single batch command",
                      (int)PFRESTObjectBatchCommandSubcommandsLimit);

    NSMutableArray *requests = [NSMutableArray arrayWithCapacity:commands.count];
    for (PFRESTCommand *command in commands) {
        NSURL *commandURL = [PFURLConstructor URLFromAbsoluteString:serverURL.absoluteString
                                                               path:command.httpPath
                                                              query:nil];
        NSMutableDictionary *requestDictionary = [@{ @"method" : command.httpMethod,
                                                     @"path" : commandURL.path } mutableCopy];
        if (command.parameters) {
            requestDictionary[@"body"] = command.parameters;
        }

        [requests addObject:requestDictionary];
    }
    return [self commandWithHTTPPath:@"batch"
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:@{ @"requests" : requests }
                        sessionToken:sessionToken];
}

@end
