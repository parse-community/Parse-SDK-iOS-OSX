/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSystemLogger.h"

#import "PFApplication.h"
#import "PFLogging.h"

@implementation PFSystemLogger

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (NSString *)_descriptionForLoggingTag:(PFLoggingTag)tag {
    NSString *description = nil;
    switch (tag) {
        case PFLoggingTagCommon:
            break;
        case PFLoggingTagCrashReporting:
            description = @"Crash Reporting";
            break;
        default:
            break;
    }
    return description;
}

+ (NSString *)_descriptionForLogLevel:(PFLogLevel)logLevel {
    NSString *description = nil;
    switch (logLevel) {
        case PFLogLevelNone:
            break;
        case PFLogLevelDebug:
            description = @"Debug";
            break;
        case PFLogLevelError:
            description = @"Error";
            break;
        case PFLogLevelWarning:
            description = @"Warning";
            break;
        case PFLogLevelInfo:
            description = @"Info";
            break;
    }
    return description;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)sharedLogger {
    static PFSystemLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[PFSystemLogger alloc] init];
    });
    return logger;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _logLevel = ([PFApplication currentApplication].appStoreEnvironment ? PFLogLevelNone : PFLogLevelWarning);

    return self;
}

///--------------------------------------
#pragma mark - Logging Messages
///--------------------------------------

- (void)logMessageWithLevel:(PFLogLevel)level
                        tag:(PFLoggingTag)tag
                     format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4) {
    if (level > self.logLevel || level == PFLogLevelNone || !format) {
        return;
    }

    va_list args;
    va_start(args, format);

    NSMutableString *message = [NSMutableString stringWithFormat:@"[%@]", [[self class] _descriptionForLogLevel:level]];

    NSString *tagDescription = [[self class] _descriptionForLoggingTag:tag];
    if (tagDescription) {
        [message appendFormat:@"[%@]", tagDescription];
    }

    [message appendFormat:@": %@", format];

    NSLogv(message, args);

    va_end(args);
}

@end
