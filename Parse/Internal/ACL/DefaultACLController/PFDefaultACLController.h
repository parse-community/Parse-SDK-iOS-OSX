/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFTask;
@class PFACL;

NS_ASSUME_NONNULL_BEGIN

@interface PFDefaultACLController : NSObject

///--------------------------------------
/// @name Init
///--------------------------------------

// TODO: (nlutsenko, richardross) Make it not terrible aka don't have singletons
+ (instancetype)defaultController;
+ (void)clearDefaultController;

///--------------------------------------
/// @name Default ACL
///--------------------------------------

/*!
 Get the default ACL managed by this controller.

 @return A task that returns the ACL encapsulated by this controller.
 */
- (BFTask *)getDefaultACLAsync;

/*!
 Set the new default default ACL to be encapsulated in this controller.

 @param acl                  The new ACL. Will be copied.
 @param accessForCurrentUser Whether or not we should add special access for the current user on this ACL.

 @return A task that returns the new (copied) ACL now encapsulated in this controller.
 */
- (BFTask *)setDefaultACLAsync:(PFACL *)acl withCurrentUserAccess:(BOOL)accessForCurrentUser;

@end

NS_ASSUME_NONNULL_END
