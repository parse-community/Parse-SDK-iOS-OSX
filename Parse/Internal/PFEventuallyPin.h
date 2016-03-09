/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>
#import <Parse/PFObject.h>
#import <Parse/PFSubclassing.h>

@class BFTask<__covariant BFGenericType>;
@protocol PFNetworkCommand;

extern NSString *const PFEventuallyPinPinName;

// Cache policies
typedef NS_ENUM(NSUInteger, PFEventuallyPinType) {
    PFEventuallyPinTypeSave = 1,
    PFEventuallyPinTypeDelete,
    PFEventuallyPinTypeCommand
};

/**
 PFEventuallyPin represents PFCommand that's save locally so that it can be executed eventually.

 Properties of PFEventuallyPin:
 - time
   Used for sort order when querying for all EventuallyPins.
 - type
   PFEventuallyPinTypeSave or PFEventuallyPinTypeDelete.
 - object
   The object the operation should notify when complete.
 - operationSetUUID
   The operationSet to be completed.
 - sessionToken
   The user that instantiated the operation.
 */
@interface PFEventuallyPin : PFObject<PFSubclassing>

@property (nonatomic, copy, readonly) NSString *uuid;

@property (nonatomic, assign, readonly) PFEventuallyPinType type;

@property (nonatomic, strong, readonly) PFObject *object;

@property (nonatomic, copy, readonly) NSString *operationSetUUID;

@property (nonatomic, copy, readonly) NSString *sessionToken;

@property (nonatomic, strong, readonly) id<PFNetworkCommand> command;

///--------------------------------------
#pragma mark - Eventually Pin
///--------------------------------------

/**
 Wrap given PFObject and PFCommand in a PFEventuallyPin with auto-generated UUID.
 */
+ (BFTask *)pinEventually:(PFObject *)object forCommand:(id<PFNetworkCommand>)command;

/**
 Wrap given PFObject and PFCommand in a PFEventuallyPin with given UUID.
 */
+ (BFTask *)pinEventually:(PFObject *)object forCommand:(id<PFNetworkCommand>)command withUUID:(NSString *)uuid;

+ (BFTask *)findAllEventuallyPin;

+ (BFTask *)findAllEventuallyPinWithExcludeUUIDs:(NSArray *)excludeUUIDs;

@end
