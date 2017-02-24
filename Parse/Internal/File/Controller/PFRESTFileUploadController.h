//
//  PFRESTFileUploadController.h
//  Parse
//
//  Created by Ken Cooper on 2/23/17.
//  Copyright © 2017 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFFileUploadController.h"

@interface PFRESTFileUploadController : NSObject <PFFileUploadController>

/**
 Uploads a file asynchronously from file path for a given file state to
 the configured Parse Server using REST. The default PFFileUploadController.
 
 @param sourceFilePath    Path to the file to upload.
 @param fileName          The PFFile's fileName.
 @param mimeType          The PFFile's mime type.
 @param sessionToken      The current users's session token.
 @param cancellationToken Cancellation token.
 @param fileController    The PFFileController initiating the upload.
 @param progressBlock     Progress block to call (optional).
 
 @return `BFTask` with a success result set to `PFFileUploadResult` containing the url and name of the uploaded file.
 */
-(BFTask<PFFileUploadResult *> * _Nonnull)uploadSourceFilePath:(NSString * _Nonnull)sourceFilePath
                                                      fileName:(NSString * _Nullable)fileName
                                                      mimeType:(NSString * _Nullable)mimeType
                                                  sessionToken:(NSString * _Nonnull)sessionToken
                                             cancellationToken:(BFCancellationToken * _Nonnull)cancellationToken
                                                fileController:(PFFileController *_Nonnull)fileController
                                                 progressBlock:(PFProgressBlock _Nonnull)progressBlock;
@end
