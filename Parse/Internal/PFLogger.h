/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

# import <Parse/PFConstants.h>

typedef uint8_t PFLoggingTag;

@interface PFLogger : NSObject

@property (atomic, assign) PFLogLevel logLevel;

///--------------------------------------
/// @name Shared Logger
///--------------------------------------

/*!
A shared instance of `PFLogger` that should be used for all logging.

@returns An shared singleton instance of `PFLogger`.
*/
+ (instancetype)sharedLogger;

///--------------------------------------
/// @name Logging Messages
///--------------------------------------

/*!
 Logs a message at a specific level for a tag.
 If current logging level doesn't include this level - this method does nothing.

 @param level  Logging Level
 @param tag    Logging Tag
 @param format Format to use for the log message.
 */
- (void)logMessageWithLevel:(PFLogLevel)level
                        tag:(PFLoggingTag)tag
                     format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

@end
