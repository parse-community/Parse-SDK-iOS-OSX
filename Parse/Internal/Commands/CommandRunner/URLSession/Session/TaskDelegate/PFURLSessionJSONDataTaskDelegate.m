/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionJSONDataTaskDelegate.h"

#import <Bolts/BFCancellationToken.h>
#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "PFCommandResult.h"
#import "PFConstants.h"
#import "PFErrorUtilities.h"
#import "PFMacros.h"
#import "PFURLSessionDataTaskDelegate_Private.h"

@interface PFURLSessionJSONDataTaskDelegate ()

@end

@implementation PFURLSessionJSONDataTaskDelegate

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (void)_taskDidFinish {
    NSData *data = [self.dataOutputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    id result = nil;

    NSError *jsonError = nil;
    if (data) {
        self.responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        result = [NSJSONSerialization JSONObjectWithData:data
                                                 options:0
                                                   error:&jsonError];

        if (jsonError && !self.error) {
            self.error = jsonError;
            [super _taskDidFinish];
            return;
        }
    }

    if (self.error) {
        NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionary];
        errorDictionary[@"code"] = @(kPFErrorConnectionFailed);
        errorDictionary[@"error"] = [self.error localizedDescription];
        errorDictionary[@"originalError"] = self.error;
        errorDictionary[NSUnderlyingErrorKey] = self.error;
        errorDictionary[@"temporary"] = @(self.response.statusCode >= 500 || self.response.statusCode < 400);
        self.error = [PFErrorUtilities errorFromResult:errorDictionary];
        [super _taskDidFinish];
        return;
    }

    if (self.response.statusCode >= 200) {
        if (self.response.statusCode < 400) {
            PFCommandResult *commandResult = [PFCommandResult commandResultWithResult:result
                                                                         resultString:self.responseString
                                                                         httpResponse:self.response];
            self.result = commandResult;
        } else if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resultDictionary = (NSDictionary *)result;
            if (resultDictionary[@"error"]) {
                NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionaryWithDictionary:resultDictionary];
                errorDictionary[@"temporary"] = @(self.response.statusCode >= 500 || self.response.statusCode < 400);
                self.error = [PFErrorUtilities errorFromResult:errorDictionary];
            }
        }
    }

    if (!self.result && !self.error) {
        self.error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer message:self.responseString];
    }
    [super _taskDidFinish];
}

@end
