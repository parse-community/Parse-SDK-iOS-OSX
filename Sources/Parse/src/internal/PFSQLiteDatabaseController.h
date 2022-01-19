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

@class BFTask<__covariant BFGenericType>;
@class PFFileManager;
@class PFSQLiteDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface PFSQLiteDatabaseController : NSObject

@property (nonatomic, strong, readonly) PFFileManager *fileManager;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithFileManager:(PFFileManager *)fileManager NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithFileManager:(PFFileManager *)fileManager;

///--------------------------------------
#pragma mark - Opening
///--------------------------------------

/**
 Asynchronously opens a database connection to the database with the name specified.
 @note Only one database can be actively open at a time.

 @param name The name of the database to open.

 @return A task, which yields a `PFSQLiteDatabase`, with the open database. 
 When the database is closed, a new database connection can be opened.
 */
- (BFTask *)openDatabaseWithNameAsync:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
