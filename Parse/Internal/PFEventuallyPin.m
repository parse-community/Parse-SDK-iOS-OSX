/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEventuallyPin.h"

#import <Bolts/BFTask.h>

#import "PFAssert.h"
#import "PFHTTPRequest.h"
#import "PFInternalUtils.h"
#import "PFObject+Subclass.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFQuery.h"
#import "PFRESTCommand.h"

NSString *const PFEventuallyPinPinName = @"_eventuallyPin";

static NSString *const PFEventuallyPinKeyUUID = @"uuid";
static NSString *const PFEventuallyPinKeyTime = @"time";
static NSString *const PFEventuallyPinKeyType = @"type";
static NSString *const PFEventuallyPinKeyObject = @"object";
static NSString *const PFEventuallyPinKeyOperationSetUUID = @"operationSetUUID";
static NSString *const PFEventuallyPinKeySessionToken = @"sessionToken";
static NSString *const PFEventuallyPinKeyCommand = @"command";

@implementation PFEventuallyPin

///--------------------------------------
#pragma mark - PFSubclassing
///--------------------------------------

+ (NSString *)parseClassName {
    return @"_EventuallyPin";
}

// Validates a class name. We override this to only allow the pin class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[self parseClassName]],
                      @"Cannot initialize a PFEventuallyPin with a custom class name.");
}

- (BOOL)needsDefaultACL {
    return NO;
}

///--------------------------------------
#pragma mark - Getter
///--------------------------------------

- (NSString *)uuid {
    return self[PFEventuallyPinKeyUUID];
}

- (PFEventuallyPinType)type {
    return [self[PFEventuallyPinKeyType] intValue];
}

- (PFObject *)object {
    return self[PFEventuallyPinKeyObject];
}

- (NSString *)operationSetUUID {
    return self[PFEventuallyPinKeyOperationSetUUID];
}

- (NSString *)sessionToken {
    return self[PFEventuallyPinKeySessionToken];
}

- (id<PFNetworkCommand>)command {
    NSDictionary *dictionary = self[PFEventuallyPinKeyCommand];
    if ([PFRESTCommand isValidDictionaryRepresentation:dictionary]) {
        return [PFRESTCommand commandFromDictionaryRepresentation:dictionary];
    }
    return nil;
}

///--------------------------------------
#pragma mark - Eventually Pin
///--------------------------------------

+ (BFTask *)pinEventually:(PFObject *)object forCommand:(id<PFNetworkCommand>)command {
    return [self pinEventually:object forCommand:command withUUID:[[NSUUID UUID] UUIDString]];
}

+ (BFTask *)pinEventually:(PFObject *)object forCommand:(id<PFNetworkCommand>)command withUUID:(NSString *)uuid {
    PFEventuallyPinType type = [self _pinTypeForCommand:command];
    NSDictionary *commandDictionary = (type == PFEventuallyPinTypeCommand ? [command dictionaryRepresentation] : nil);
    return [self _pinEventually:object
                           type:type
                           uuid:uuid
               operationSetUUID:command.operationSetUUID
                   sessionToken:command.sessionToken
              commandDictionary:commandDictionary];
}

+ (BFTask *)findAllEventuallyPin {
    return [self findAllEventuallyPinWithExcludeUUIDs:nil];
}

+ (BFTask *)findAllEventuallyPinWithExcludeUUIDs:(NSArray *)excludeUUIDs {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query fromPinWithName:PFEventuallyPinPinName];
    [query orderByAscending:PFEventuallyPinKeyTime];

    if (excludeUUIDs != nil) {
        [query whereKey:PFEventuallyPinKeyUUID notContainedIn:excludeUUIDs];
    }

    return [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
        NSArray *pins = task.result;
        NSMutableArray *fetchTasks = [NSMutableArray array];

        for (PFEventuallyPin *pin in pins) {
            PFObject *object = pin.object;
            if (object != nil) {
                [fetchTasks addObject:[object fetchFromLocalDatastoreInBackground]];
            }
        }

        return [[BFTask taskForCompletionOfAllTasks:fetchTasks] continueWithBlock:^id(BFTask *task) {
            return [BFTask taskWithResult:pins];
        }];
    }];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

+ (BFTask *)_pinEventually:(PFObject *)object
                      type:(PFEventuallyPinType)type
                      uuid:(NSString *)uuid
          operationSetUUID:(NSString *)operationSetUUID
              sessionToken:(NSString *)sessionToken
         commandDictionary:(NSDictionary *)commandDictionary {
    PFEventuallyPin *pin = [[PFEventuallyPin alloc] init];
    pin[PFEventuallyPinKeyUUID] = uuid;
    pin[PFEventuallyPinKeyTime] = [NSDate date];
    pin[PFEventuallyPinKeyType] = @(type);
    if (object != nil) {
        pin[PFEventuallyPinKeyObject] = object;
    }
    if (operationSetUUID != nil) {
        pin[PFEventuallyPinKeyOperationSetUUID] = operationSetUUID;
    }
    if (sessionToken != nil) {
        pin[PFEventuallyPinKeySessionToken] = sessionToken;
    }
    if (commandDictionary != nil) {
        pin[PFEventuallyPinKeyCommand] = commandDictionary;
    }

    // NOTE: This is needed otherwise ARC releases the pins before we have a chance to persist the new ones to disk,
    // Which means we'd lose any columns on objects in eventually pins not currently in memory.
    __block NSArray *existingPins = nil;
    return [[[self findAllEventuallyPin] continueWithSuccessBlock:^id(BFTask *task) {
        existingPins = task.result;
        return [pin pinInBackgroundWithName:PFEventuallyPinPinName];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        existingPins = nil;
        return pin;
    }];
}

+ (PFEventuallyPinType)_pinTypeForCommand:(id<PFNetworkCommand>)command {
    PFEventuallyPinType type = PFEventuallyPinTypeCommand;
    NSString *path = [(PFRESTCommand *)command httpPath];
    NSString *method = [(PFRESTCommand *)command httpMethod];
    if ([path hasPrefix:@"classes"]) {
        if ([method isEqualToString:PFHTTPRequestMethodPOST] ||
            [method isEqualToString:PFHTTPRequestMethodPUT]) {
            type = PFEventuallyPinTypeSave;
        } else if ([method isEqualToString:PFHTTPRequestMethodDELETE]) {
            type = PFEventuallyPinTypeDelete;
        }
    }
    return type;
}

@end
