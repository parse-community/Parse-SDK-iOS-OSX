//
//  PFUploadController.h
//  Parse
//
//  Created by Ken Cooper on 2/20/17.
//  Copyright © 2017 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bolts/BFTask.h>

/**
 Response provided by a custom `PFFileUploadController`.
 */
@interface PFFileUploadResult : NSObject
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *name;
@end


/**
 A policy interface for overriding the default upload behavior of uploading a PFFile
 to application's parse server. Allows for direct uploads to other file storage
 providers.
 */
@protocol PFFileUploadController <NSObject>

/**
 Uploads a file asynchronously from file path for a given file state.
 
 @param sourceFilePath    Path to the file to upload.
 @param fileName          The PFFile's fileName.
 @param mimeType          The PFFile's mime type.
 @param progressBlock     Progress block to call (optional).
 
 @return `BFTask` with a success result set to `PFFileUploadResult` containing the url and name of the uploaded file.
 */
-(BFTask<PFFileUploadResult *> *)uploadSourceFilePath:(NSString *)sourceFilePath
                                             fileName:(NSString *)fileName
                                             mimeType:(NSString *)mimeType
                                        progressBlock:(PFProgressBlock)progressBlock;
@end
