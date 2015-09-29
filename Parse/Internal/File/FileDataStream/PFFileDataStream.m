/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileDataStream.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface PFFileDataStream() <NSStreamDelegate> {
    NSString *_path;
    NSInputStream *_inputStream;

    int _fd;
    BOOL _finished;

    __weak id<NSStreamDelegate> _delegate;
}

@end

@implementation PFFileDataStream

- (instancetype)initWithFileAtPath:(NSString *)path {
    _finished = NO;

    _path = path;
    _inputStream = [NSInputStream inputStreamWithFileAtPath:path];
    _inputStream.delegate = self;

    return self;
}

- (void)stopBlocking {
    _finished = YES;

    [self stream:_inputStream handleEvent:NSStreamEventHasBytesAvailable];
}

///--------------------------------------
#pragma mark - NSProxy methods
///--------------------------------------

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_inputStream methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:_inputStream];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    Method implementation = class_getInstanceMethod([self class], aSelector);
    return implementation ? YES : [_inputStream respondsToSelector:aSelector];
}

///--------------------------------------
#pragma mark - NSInputStream methods
///--------------------------------------

- (void)setDelegate:(id<NSStreamDelegate>)delegate {
    _delegate = delegate;
}

- (id<NSStreamDelegate>)delegate {
    return _delegate;
}

- (void)open {
    _fd = open([_path UTF8String], O_RDONLY | O_NONBLOCK);
    [_inputStream open];
}

- (void)close {
    [_inputStream close];
    close(_fd);
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (!_finished) {
        off_t currentOffset = [[_inputStream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedLongLongValue];
        off_t fileSize = lseek(_fd, 0, SEEK_END);

        len = (NSUInteger)MIN(len, ((fileSize - currentOffset) - 1));
    }

    // Reading 0 bytes from an NSInputStream causes this strange undocumented behavior: it marks the stream as 'at end',
    // regardless of whether more bytes are available or not. lolwut?
    if (len == 0) {
        return 0;
    }

    return [_inputStream read:buffer maxLength:len];
}

///--------------------------------------
#pragma mark - NSStreamDelegate
///--------------------------------------

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(stream:handleEvent:)]) {
        [delegate stream:(NSInputStream *)self handleEvent:eventCode];
    }
}

@end
