//
//  PFUploadController.h
//  Parse
//
//  Created by Ken Cooper on 2/20/17.
//  Copyright © 2017 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<Bolts/BFTask.h>)
#import <Bolts/BFTask.h>
#else
#import "BFTask.h"
#endif

#import "PFFileUploadResult.h"

/**
 A policy interface for overriding the default upload behavior of uploading a PFFileObject
 to application's parse server. Allows for direct uploads to other file storage
 providers.
 */
@protocol PFFileUploadController <NSObject>

/**
 Uploads a file asynchronously from file path for a given file state.
 
 @param sourceFilePath    Path to the file to upload.
 @param fileName          The PFFileObject's fileName.
 @param mimeType          The PFFileObject's mime type.
 @param sessionToken      The current users's session token.
 @param cancellationToken Cancellation token.
 @param progressBlock     Progress block to call (optional).
 
 @return `BFTask` with a success result set to `PFFileUploadResult` containing the url and name of the uploaded file.
 */
-(BFTask<PFFileUploadResult *> * _Nonnull)uploadSourceFilePath:(NSString * _Nonnull)sourceFilePath
                                                      fileName:(NSString * _Nullable)fileName
                                                      mimeType:(NSString * _Nullable)mimeType
                                                  sessionToken:(NSString * _Nonnull)sessionToken
                                             cancellationToken:(BFCancellationToken * _Nonnull)cancellationToken
                                                 progressBlock:(PFProgressBlock _Nonnull)progressBlock;
@end
