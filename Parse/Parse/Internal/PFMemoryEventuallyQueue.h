/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEventuallyQueue.h"

PF_IOS_UNAVAILABLE_WARNING
PF_OSX_UNAVAILABLE_WARNING
PF_WATCH_UNAVAILABLE_WARNING

PF_IOS_UNAVAILABLE PF_OSX_UNAVAILABLE PF_WATCH_UNAVAILABLE @interface PFMemoryEventuallyQueue : PFEventuallyQueue

+ (instancetype)newDefaultMemoryEventuallyQueueWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

@end
