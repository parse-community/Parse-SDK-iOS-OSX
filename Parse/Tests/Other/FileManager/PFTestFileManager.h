/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileManager.h"

/**
 A `PFFileManager` subclass to mock file manager instances with. Unlike a class mock of `PFFileManager`, a class mock of
 this subclass doesn't take over the class methods of `PFFileManager`, so it can't break their calls on background threads
 when the mock is stopped.
 */
@interface PFTestFileManager : PFFileManager

@end
