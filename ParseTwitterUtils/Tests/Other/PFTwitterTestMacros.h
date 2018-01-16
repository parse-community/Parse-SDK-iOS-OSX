/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef PFTwitterTestMacros_h
#define PFTwitterTestMacros_h

/**
 To prevent retain cycles by OCMock, this macro allows us to capture a weak reference to return from a stubbed method.
 */
#define andReturnWeak(variable) _andDo(                                              \
    ({                                                                               \
        __weak typeof(variable) variable ## _weak = (variable);                      \
        ^(NSInvocation *invocation) {                                                \
            __autoreleasing typeof(variable) variable ## _block = variable ## _weak; \
            [invocation setReturnValue:&(variable ## _block)];                       \
        };                                                                           \
    })                                                                               \
)

#endif /* PFTwitterTestMacros_h */
