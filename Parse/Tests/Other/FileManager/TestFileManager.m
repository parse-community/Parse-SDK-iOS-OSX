/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "TestFileManager.h"

@interface TestFileManagerDirectoryEnumerator : NSObject

- (instancetype)initWithFileManager:(TestFileManager *)manager path:(NSString *)path;

- (NSDictionary *)fileAttributes;
- (void)skipDescendants;
- (id)nextObject;

@end

@implementation TestFileManager {
    // Use public so the directory enumerator can use all of these. Not encapsulated properly, but this is just a test
    // class.
@public
    NSTimeInterval _lastReturnedTime;

    NSMutableDictionary *_fileAttributes;
    NSMutableDictionary *_fileContents;
    dispatch_queue_t _queue;
}

+ (NSFileManager *)fileManager {
    return (NSFileManager *)[[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _lastReturnedTime = 0;
    _fileAttributes = [NSMutableDictionary new];
    _fileContents = [NSMutableDictionary new];
    _queue = dispatch_queue_create("com.parse.testfilemanager.sync", DISPATCH_QUEUE_SERIAL);

    return self;
}

- (NSData *)contentsAtPath:(NSString *)path {
    __block NSData *results = nil;
    dispatch_sync(_queue, ^{
        results = self->_fileContents[path];
    });

    return results;
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attributes {
    dispatch_sync(_queue, ^{
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self->_lastReturnedTime++];

        newAttributes[NSFileModificationDate] = newAttributes[NSURLContentModificationDateKey] = date;
        newAttributes[NSFileSize] = @([data length]);

        self->_fileContents[path] = data;
        [self->_fileAttributes setObject:newAttributes forKey:path];

    });
    return YES;
}

- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError **)error {
    dispatch_sync(_queue, ^{
        [self->_fileContents removeObjectForKey:URL.path];
        [self->_fileAttributes removeObjectForKey:URL.path];
    });

    return YES;
}

- (BOOL)createDirectoryAtURL:(NSURL *)url
 withIntermediateDirectories:(BOOL)createIntermediates
                  attributes:(NSDictionary *)attributes
                       error:(NSError **)error {
    // No-op
    return YES;
}

- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)path {
    return (NSDirectoryEnumerator *) [[TestFileManagerDirectoryEnumerator alloc] initWithFileManager:self path:path];
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
    __block NSDictionary *results = nil;
    dispatch_sync(_queue, ^{
        results = [self->_fileAttributes[path] copy];
    });

    return results;
}

- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error {
    dispatch_sync(_queue, ^{
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self->_lastReturnedTime++];

        newAttributes[NSFileModificationDate] = newAttributes[NSURLContentModificationDateKey] = date;

        [self->_fileAttributes[path] addEntriesFromDictionary:newAttributes];
    });

    return YES;
}

@end

@implementation TestFileManagerDirectoryEnumerator {
    TestFileManager *_manager;
    NSString *_path;

    NSString *_currentPath;
    NSEnumerator *_enumerator;
}

- (instancetype)initWithFileManager:(TestFileManager *)manager path:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    _manager = manager;
    _path = [path copy];

    dispatch_sync(_manager->_queue, ^{
        self->_enumerator = [manager->_fileContents keyEnumerator];
    });

    return self;
}

- (NSDictionary *)fileAttributes {
    __block NSDictionary *results = nil;
    dispatch_sync(_manager->_queue, ^{
        results = [self->_manager->_fileAttributes[self->_currentPath] copy];
    });

    return results;
}

- (id)nextObject {
    dispatch_sync(_manager->_queue, ^{
        self->_currentPath = nil;
        while (true) {
            if ([self->_currentPath hasPrefix:self->_path]) break;
            self->_currentPath = [self->_enumerator nextObject];

            if (!self->_currentPath) break;
        }
    });

    return [self->_currentPath lastPathComponent];
}

- (void)skipDescendants {
    // No-op
}

@end
