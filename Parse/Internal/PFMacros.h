/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/NSObjCRuntime.h>
#import <os/object.h>

#ifndef Parse_PFMacros_h
#define Parse_PFMacros_h

/*!
 This macro allows to create NSSet via subscript.
 */
#define PF_SET(...)  [NSSet setWithObjects:__VA_ARGS__, nil]

/*!
 This macro is a handy thing for converting libSystem objects to (void *) pointers.
 If you are targeting OSX 10.8+ and iOS 6.0+ - this is no longer required.
 */
#if OS_OBJECT_USE_OBJC
    #define PFOSObjectPointer(object) \
    (__bridge void *)(object)
#else
    #define PFOSObjectPointer(object) \
    (void *)(object)
#endif

/*!
 Mark a queue in order to be able to check PFAssertIsOnMarkedQueue.
 */
#define PFMarkDispatchQueue(queue) \
dispatch_queue_set_specific((queue), \
                            PFOSObjectPointer(queue), \
                            PFOSObjectPointer(queue), \
                            NULL)

///--------------------------------------
/// @name Memory Management
///
/// The following macros are influenced and include portions of libextobjc.
///--------------------------------------

/*!
 Creates a __weak version of the variable provided,
 which can later be safely used or converted into strong variable via @strongify.
 */
#define weakify(var) \
try {} @catch (...) {} \
__weak __typeof__(var) var ## _weak = var;

/*!
 Creates a strong shadow reference of the variable provided.
 Variable must have previously been passed to @weakify.
 */
#define strongify(var) \
try {} @catch (...) {} \
__strong __typeof__(var) var = var ## _weak;

///--------------------------------------
/// @name KVC
///--------------------------------------

/*!
 This macro ensures that object.key exists at compile time.
 It can accept a chained key path.
 */
#define keypath(TYPE, PATH) \
(((void)(NO && ((void)((TYPE *)(nil)).PATH, NO)), # PATH))

///--------------------------------------
/// @name Runtime
///--------------------------------------

/*!
 Using objc_msgSend directly is bad, very bad. Doing so without casting could result in stack-smashing on architectures
 (*cough* x86 *cough*) that use strange methods of returning values of different types.

 The objc_msgSend_safe macro ensures that we properly cast the function call to use the right conventions when passing
 parameters and getting return values. This also fixes some issues with ARC and objc_msgSend directly, though strange
 things can happen when receiving values from NS_RETURNS_RETAINED methods.
 */
#define objc_msgSend(...)  _Pragma("GCC error \"Use objc_msgSend_safe() instead!\"")
#define objc_msgSend_safe(returnType, argTypes...) ((returnType (*)(id, SEL, ##argTypes))(objc_msgSend))

/*!
 This exists because if we throw an exception from dispatch_sync, it doesn't 'bubble up' to the calling thread.
 This simply wraps dispatch_sync and properly throws the exception back to the calling thread, not the thread that
 the exception was originally raised on.

 @param queue The queue to execute on
 @param block The block to execute

 @see dispatch_sync
 */
#define pf_sync_with_throw(queue, block)      \
    do {                                      \
        __block NSException *caught = nil;    \
        dispatch_sync(queue, ^{              \
            @try { block(); }                 \
            @catch (NSException *ex) {        \
                caught = ex;                  \
            }                                 \
        });                                   \
        if (caught) @throw caught;            \
    } while (0)

/*!
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

#endif
