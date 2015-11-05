/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFACL.h>

@class PFUser;

@interface PFACL (Private)

// Internal commands

/*
 Gets the encoded format for an ACL.
 */
- (NSDictionary *)encodeIntoDictionary;

/*
 Creates a new ACL object from an existing dictionary.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/*!
 Creates an ACL from its encoded format.
 */
+ (instancetype)ACLWithDictionary:(NSDictionary *)dictionary;

- (void)setShared:(BOOL)shared;
- (BOOL)isShared;
- (instancetype)createUnsharedCopy;
- (BOOL)hasUnresolvedUser;

+ (instancetype)defaultACL;

@end
