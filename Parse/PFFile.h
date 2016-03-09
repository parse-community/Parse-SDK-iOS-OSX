/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>

#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `PFFile` representes a file of binary data stored on the Parse servers.
 This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
@interface PFFile : NSObject

///--------------------------------------
#pragma mark - Creating a PFFile
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Creates a file with given data. A name will be assigned to it by the server.

 @param data The contents of the new `PFFile`.

 @return A new `PFFile`.
 */
+ (nullable instancetype)fileWithData:(NSData *)data;

/**
 Creates a file with given data and name.

 @param name The name of the new PFFile. The file name must begin with and
 alphanumeric character, and consist of alphanumeric characters, periods,
 spaces, underscores, or dashes.
 @param data The contents of the new `PFFile`.

 @return A new `PFFile` object.
 */
+ (nullable instancetype)fileWithName:(nullable NSString *)name data:(NSData *)data;

/**
 Creates a file with the contents of another file.

 @warning This method raises an exception if the file at path is not accessible
 or if there is not enough disk space left.

 @param name  The name of the new `PFFile`. The file name must begin with and alphanumeric character,
 and consist of alphanumeric characters, periods, spaces, underscores, or dashes.
 @param path  The path to the file that will be uploaded to Parse.

 @return A new `PFFile` instance.
 */
+ (nullable instancetype)fileWithName:(nullable NSString *)name
                       contentsAtPath:(NSString *)path PF_SWIFT_UNAVAILABLE;

/**
 Creates a file with the contents of another file.

 @param name  The name of the new `PFFile`. The file name must begin with and alphanumeric character,
 and consist of alphanumeric characters, periods, spaces, underscores, or dashes.
 @param path  The path to the file that will be uploaded to Parse.
 @param error On input, a pointer to an error object.
 If an error occurs, this pointer is set to an actual error object containing the error information.
 You may specify `nil` for this parameter if you do not want the error information.

 @return A new `PFFile` instance or `nil` if the error occured.
 */
+ (nullable instancetype)fileWithName:(nullable NSString *)name
                       contentsAtPath:(NSString *)path
                                error:(NSError **)error;

/**
 Creates a file with given data, name and content type.

 @warning This method raises an exception if the data supplied is not accessible or could not be saved.

 @param name        The name of the new `PFFile`. The file name must begin with and alphanumeric character,
 and consist of alphanumeric characters, periods, spaces, underscores, or dashes.
 @param data        The contents of the new `PFFile`.
 @param contentType Represents MIME type of the data.

 @return A new `PFFile` instance.
 */
+ (nullable instancetype)fileWithName:(nullable NSString *)name
                                 data:(NSData *)data
                          contentType:(nullable NSString *)contentType PF_SWIFT_UNAVAILABLE;

/**
 Creates a file with given data, name and content type.

 @param name        The name of the new `PFFile`. The file name must begin with and alphanumeric character,
 and consist of alphanumeric characters, periods, spaces, underscores, or dashes.
 @param data        The contents of the new `PFFile`.
 @param contentType Represents MIME type of the data.
 @param error On input, a pointer to an error object.
 If an error occurs, this pointer is set to an actual error object containing the error information.
 You may specify `nil` for this parameter if you do not want the error information.

 @return A new `PFFile` instance or `nil` if the error occured.
 */
+ (nullable instancetype)fileWithName:(nullable NSString *)name
                                 data:(NSData *)data
                          contentType:(nullable NSString *)contentType
                                error:(NSError **)error;

/**
 Creates a file with given data and content type.

 @param data The contents of the new `PFFile`.
 @param contentType Represents MIME type of the data.

 @return A new `PFFile` object.
 */
+ (instancetype)fileWithData:(NSData *)data contentType:(nullable NSString *)contentType;

///--------------------------------------
#pragma mark - File Properties
///--------------------------------------

/**
 The name of the file.

 Before the file is saved, this is the filename given by
 the user. After the file is saved, that name gets prefixed with a unique
 identifier.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 The url of the file.
 */
@property (nullable, nonatomic, copy, readonly) NSString *url;

/**
 Whether the file has been uploaded for the first time.
 */
@property (nonatomic, assign, readonly, getter=isDirty) BOOL dirty;

///--------------------------------------
#pragma mark - Storing Data with Parse
///--------------------------------------

/**
 Saves the file *asynchronously*.

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveInBackground;

/**
 Saves the file *asynchronously*

 @param progressBlock The block should have the following argument signature: `^(int percentDone)`

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveInBackgroundWithProgressBlock:(nullable PFProgressBlock)progressBlock;

/**
 Saves the file *asynchronously* and executes the given block.

 @param block The block should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
- (void)saveInBackgroundWithBlock:(nullable PFBooleanResultBlock)block;

/**
 Saves the file *asynchronously* and executes the given block.

 This method will execute the progressBlock periodically with the percent progress.
 `progressBlock` will get called with `100` before `resultBlock` is called.

 @param block The block should have the following argument signature: `^(BOOL succeeded, NSError *error)`
 @param progressBlock The block should have the following argument signature: `^(int percentDone)`
 */
- (void)saveInBackgroundWithBlock:(nullable PFBooleanResultBlock)block
                    progressBlock:(nullable PFProgressBlock)progressBlock;

///--------------------------------------
#pragma mark - Getting Data from Parse
///--------------------------------------

/**
 Whether the data is available in memory or needs to be downloaded.
 */
@property (nonatomic, assign, readonly, getter=isDataAvailable) BOOL dataAvailable;

/**
 This method is like `-getData` but it fetches asynchronously to avoid blocking the current thread.

 @see getData

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSData *> *)getDataInBackground;

/**
 This method is like `-getData` but it fetches asynchronously to avoid blocking the current thread.

 This can help applications with many large files avoid memory warnings.

 @see getData

 @param progressBlock The block should have the following argument signature: ^(int percentDone)

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSData *> *)getDataInBackgroundWithProgressBlock:(nullable PFProgressBlock)progressBlock;

/**
 This method is like `-getDataInBackground` but avoids ever holding the entire `PFFile` contents in memory at once.

 This can help applications with many large files avoid memory warnings.

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSInputStream *> *)getDataStreamInBackground;

/**
 This method is like `-getDataStreamInBackground`, but yields a live-updating stream.

 Instead of `-getDataStream`, which yields a stream that can be read from only after the request has
 completed, this method gives you a stream directly written to by the HTTP session. As this stream is not pre-buffered,
 it is strongly advised to use the `NSStreamDelegate` methods, in combination with a run loop, to consume the data in
 the stream, to do proper async file downloading.

 @note You MUST open this stream before reading from it.
 @note Do NOT call `waitUntilFinished` on this task from the main thread. It may result in a deadlock.

 @return A task that produces a *live* stream that is being written to with the data from the server.
 */
- (BFTask<NSInputStream *> *)getDataDownloadStreamInBackground;

/**
 This method is like `-getDataInBackground` but avoids
 ever holding the entire `PFFile` contents in memory at once.

 This can help applications with many large files avoid memory warnings.
 @param progressBlock The block should have the following argument signature: ^(int percentDone)

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSInputStream *> *)getDataStreamInBackgroundWithProgressBlock:(nullable PFProgressBlock)progressBlock;

/**
 This method is like `-getDataStreamInBackgroundWithProgressBlock:`, but yields a live-updating stream.

 Instead of `-getDataStream`, which yields a stream that can be read from only after the request has
 completed, this method gives you a stream directly written to by the HTTP session. As this stream is not pre-buffered,
 it is strongly advised to use the `NSStreamDelegate` methods, in combination with a run loop, to consume the data in
 the stream, to do proper async file downloading.

 @note You MUST open this stream before reading from it.
 @note Do NOT call `waitUntilFinished` on this task from the main thread. It may result in a deadlock.

 @param progressBlock The block should have the following argument signature: `^(int percentDone)`

 @return A task that produces a *live* stream that is being written to with the data from the server.
 */
- (BFTask<NSInputStream *> *)getDataDownloadStreamInBackgroundWithProgressBlock:(nullable PFProgressBlock)progressBlock;

/**
 *Asynchronously* gets the data from cache if available or fetches its contents from the network.

 @param block The block should have the following argument signature: `^(NSData *result, NSError *error)`
 */
- (void)getDataInBackgroundWithBlock:(nullable PFDataResultBlock)block;

/**
 This method is like `-getDataInBackgroundWithBlock:` but avoids ever holding the entire `PFFile` contents in memory at once.

 This can help applications with many large files avoid memory warnings.

 @param block The block should have the following argument signature: `(NSInputStream *result, NSError *error)`
 */
- (void)getDataStreamInBackgroundWithBlock:(nullable PFDataStreamResultBlock)block;

/**
 *Asynchronously* gets the data from cache if available or fetches its contents from the network.

 This method will execute the progressBlock periodically with the percent progress.
 `progressBlock` will get called with `100` before `resultBlock` is called.

 @param resultBlock The block should have the following argument signature: ^(NSData *result, NSError *error)
 @param progressBlock The block should have the following argument signature: ^(int percentDone)
 */
- (void)getDataInBackgroundWithBlock:(nullable PFDataResultBlock)resultBlock
                       progressBlock:(nullable PFProgressBlock)progressBlock;

/**
 This method is like `-getDataInBackgroundWithBlock:progressBlock:` but avoids
 ever holding the entire `PFFile` contents in memory at once.

 This can help applications with many large files avoid memory warnings.

 @param resultBlock The block should have the following argument signature: `^(NSInputStream *result, NSError *error)`.
 @param progressBlock The block should have the following argument signature: `^(int percentDone)`.
 */
- (void)getDataStreamInBackgroundWithBlock:(nullable PFDataStreamResultBlock)resultBlock
                             progressBlock:(nullable PFProgressBlock)progressBlock;

/**
 *Asynchronously* gets the file path for file from cache if available or fetches its contents from the network.

 @note The file path may change between versions of SDK.
 @note If you overwrite the contents of the file at returned path it will persist those change
 until the file cache is cleared.

 @return The task, with the result set to `NSString` representation of a file path.
 */
- (BFTask<NSString *> *)getFilePathInBackground;

/**
 *Asynchronously* gets the file path for file from cache if available or fetches its contents from the network.

 @note The file path may change between versions of SDK.
 @note If you overwrite the contents of the file at returned path it will persist those change
 until the file cache is cleared.

 @param progressBlock The block should have the following argument signature: `^(int percentDone)`.

 @return The task, with the result set to `NSString` representation of a file path.
 */
- (BFTask<NSString *> *)getFilePathInBackgroundWithProgressBlock:(nullable PFProgressBlock)progressBlock;

/**
 *Asynchronously* gets the file path for file from cache if available or fetches its contents from the network.

 @note The file path may change between versions of SDK.
 @note If you overwrite the contents of the file at returned path it will persist those change
 until the file cache is cleared.

 @param block The block should have the following argument signature: `^(NSString *filePath, NSError *error)`.
 */
- (void)getFilePathInBackgroundWithBlock:(nullable PFFilePathResultBlock)block;

/**
 *Asynchronously* gets the file path for file from cache if available or fetches its contents from the network.

 @note The file path may change between versions of SDK.
 @note If you overwrite the contents of the file at returned path it will persist those change
 until the file cache is cleared.

 @param block The block should have the following argument signature: `^(NSString *filePath, NSError *error)`.
 @param progressBlock The block should have the following argument signature: `^(int percentDone)`.
 */
- (void)getFilePathInBackgroundWithBlock:(nullable PFFilePathResultBlock)block
                           progressBlock:(nullable PFProgressBlock)progressBlock;

///--------------------------------------
#pragma mark - Interrupting a Transfer
///--------------------------------------

/**
 Cancels the current request (upload or download of file).
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
