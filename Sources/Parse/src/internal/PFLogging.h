/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef Parse_PFLogging_h
#define Parse_PFLogging_h

#import <Parse/PFConstants.h>

#import "PFSystemLogger.h"

static const PFLoggingTag PFLoggingTagCommon = 0;
static const PFLoggingTag PFLoggingTagCrashReporting = 100;

#define PFLog(level, loggingTag, frmt, ...) \
[[PFSystemLogger sharedLogger] logMessageWithLevel:level tag:loggingTag format:(frmt), ##__VA_ARGS__]

#define PFLogError(tag, frmt, ...) \
PFLog(PFLogLevelError, (tag), (frmt), ##__VA_ARGS__)

#define PFLogWarning(tag, frmt, ...) \
PFLog(PFLogLevelWarning, (tag), (frmt), ##__VA_ARGS__)

#define PFLogInfo(tag, frmt, ...) \
PFLog(PFLogLevelInfo, (tag), (frmt), ##__VA_ARGS__)

#define PFLogDebug(tag, frmt, ...) \
PFLog(PFLogLevelDebug, (tag), (frmt), ##__VA_ARGS__)

#define PFLogException(exception) \
PFLogError(PFLoggingTagCommon, @"Caught \"%@\" with reason \"%@\"%@", \
exception.name, exception, \
[exception callStackSymbols] ? [NSString stringWithFormat:@":\n%@.", [exception callStackSymbols]] : @"")

#endif
