/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ParseModule.h"

///--------------------------------------
#pragma mark - ParseModuleCollection
///--------------------------------------

typedef void (^ParseModuleEnumerationBlock)(id<ParseModule> module, BOOL *stop, BOOL *remove);

@interface ParseModuleCollection ()

@property (atomic, strong) dispatch_queue_t collectionQueue;
@property (atomic, strong) NSPointerArray *modules;

@end

@implementation ParseModuleCollection

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (self) {
        _collectionQueue = dispatch_queue_create("com.parse.ParseModuleCollection", DISPATCH_QUEUE_SERIAL);
        _modules = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

///--------------------------------------
#pragma mark - Collection
///--------------------------------------

- (void)addParseModule:(id<ParseModule>)module {
    if (module == nil) {
        return;
    }

    [self performCollectionAccessBlock:^{
        [self.modules addPointer:(__bridge void *)module];
    }];
}

- (void)removeParseModule:(id<ParseModule>)module {
    if (module == nil) {
        return;
    }

    [self enumerateModulesWithBlock:^(id<ParseModule> enumeratedModule, BOOL *stop, BOOL *remove) {
        *remove = (module == enumeratedModule);
    }];
}

- (BOOL)containsModule:(id<ParseModule>)module {
    __block BOOL retValue = NO;
    [self enumerateModulesWithBlock:^(id<ParseModule> enumeratedModule, BOOL *stop, BOOL *remove) {
        if (module == enumeratedModule) {
            retValue = YES;
            *stop = YES;
        }
    }];
    return retValue;
}

- (NSUInteger)modulesCount {
    return [self.modules count];
}

///--------------------------------------
#pragma mark - ParseModule
///--------------------------------------

- (void)parseDidInitializeWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    [self enumerateModulesWithBlock:^(id<ParseModule> module, BOOL *stop, BOOL *remove) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [module parseDidInitializeWithApplicationId:applicationId clientKey:clientKey];
        });
    }];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (void)performCollectionAccessBlock:(dispatch_block_t)block {
    dispatch_sync(self.collectionQueue, block);
}

/*!
 Enumerates all existing modules in this collection.

 NOTE: This **will modify the contents of the collection** if any of the modules were deallocated since last loop.

 @param block the block to enumerate with.
 */
- (void)enumerateModulesWithBlock:(ParseModuleEnumerationBlock)block {
    [self performCollectionAccessBlock:^{
        NSMutableIndexSet *toRemove = [[NSMutableIndexSet alloc] init];

        NSUInteger index = 0;
        BOOL stop = NO;

        for (__strong id<ParseModule> module in self.modules) {
            BOOL remove = module == nil;
            if (!remove) {
                block(module, &stop, &remove);
            }

            if (remove) {
                [toRemove addIndex:index];
            }

            if (stop) break;
            index++;
        }

        // NSPointerArray doesn't have a -removeObjectsAtIndexes:... WHY!?!?
        for (index = toRemove.firstIndex; index != NSNotFound; index = [toRemove indexGreaterThanIndex:index]) {
            [self.modules removePointerAtIndex:index];
        }
    }];
}

@end
