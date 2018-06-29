/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "OCMock+Parse.h"

@import Bolts.BFTask;

#import "PFCommandResult.h"
#import "PFCommandRunning.h"

@implementation OCMockObject (PFCOmmandRunning)

- (void)mockCommandResult:(id)result forCommandsPassingTest:(BOOL (^)(PFRESTCommand *command))block {
    PFCommandResult *commandResult = [PFCommandResult commandResultWithResult:result
                                                                 resultString:nil
                                                                 httpResponse:nil];
    BFTask *task = [BFTask taskWithResult:commandResult];
    OCMStub([[(id)self ignoringNonObjectArgs] runCommandAsync:[OCMArg checkWithBlock:block]
                                                  withOptions:0]).andReturn(task);
    OCMStub([[(id)self ignoringNonObjectArgs] runCommandAsync:[OCMArg checkWithBlock:block]
                                                  withOptions:0
                                            cancellationToken:OCMOCK_ANY]).andReturn(task);
}

@end
