/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMacros.h"

#ifndef Parse_PFAssert_h
#define Parse_PFAssert_h

/**
 Raises an `NSInvalidArgumentException` if the `condition` does not pass.
 Use `description` to supply the way to fix the exception.
 */
#define PFParameterAssert(condition, description, ...) \
    do {\
        if (!(condition)) { \
            [NSException raise:NSInvalidArgumentException \
                        format:description, ##__VA_ARGS__]; \
        } \
    } while(0)

/**
 Raises an `NSRangeException` if the `condition` does not pass.
 Use `description` to supply the way to fix the exception.
 */
#define PFRangeAssert(condition, description, ...) \
    do {\
        if (!(condition)) { \
            [NSException raise:NSRangeException \
                        format:description, ##__VA_ARGS__]; \
    } \
} while(0)

/**
 Raises an `NSInternalInconsistencyException` if the `condition` does not pass.
 Use `description` to supply the way to fix the exception.
 */
#define PFConsistencyAssert(condition, description, ...) \
    do { \
        if (!(condition)) { \
            [NSException raise:NSInternalInconsistencyException \
                        format:description, ##__VA_ARGS__]; \
        } \
    } while(0)

/**
 Always raises `NSInternalInconsistencyException` with details
 about the method used and class that received the message
 */
#define PFNotDesignatedInitializer() \
do { \
    PFConsistencyAssert(NO, \
                        @"%@ is not the designated initializer for instances of %@.", \
                        NSStringFromSelector(_cmd), \
                        NSStringFromClass([self class])); \
    return nil; \
} while (0)

/**
 Raises `NSInternalInconsistencyException` if current thread is not main thread.
 */
#define PFAssertMainThread() \
do { \
    PFConsistencyAssert([NSThread isMainThread], @"This method must be called on the main thread."); \
} while (0)

/**
 Raises `NSInternalInconsistencyException` if current thread is not the required one.
 */
#define PFAssertIsOnThread(thread) \
do { \
    PFConsistencyAssert([NSThread currentThread] == thread, \
                        @"This method must be called only on thread: %@.", thread); \
} while (0)

/**
 Raises `NSInternalInconsistencyException` if the current queue
 is not the same as the queue provided.
 Make sure you mark the queue first via `PFMarkDispatchQueue`
 */
#define PFAssertIsOnDispatchQueue(queue) \
do { \
    void *mark = PFOSObjectPointer(queue); \
    PFConsistencyAssert(dispatch_get_specific(mark) == mark, \
                        @"%s must be executed on %s", \
                        __PRETTY_FUNCTION__, dispatch_queue_get_label(queue)); \
} while (0)

#endif
