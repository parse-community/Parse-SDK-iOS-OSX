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

@interface PFSystemLogger : NSObject

@property (atomic, assign) PFLogLevel logLevel;

///--------------------------------------
#pragma mark - Shared Logger
///--------------------------------------

/**
A shared instance of `PFSystemLogger` that should be used for all logging.

@return An shared singleton instance of `PFSystemLogger`.
*/
+ (instancetype)sharedLogger; //TODO: (nlutsenko) Convert to use an instance everywhere instead of a shared singleton.

///--------------------------------------
#pragma mark - Logging Messages
///--------------------------------------

/**
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
