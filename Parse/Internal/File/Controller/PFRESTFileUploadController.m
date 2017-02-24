//
//  PFRESTFileUploadController.m
//  Parse
//
//  Created by Ken Cooper on 2/23/17.
//  Copyright © 2017 Parse Inc. All rights reserved.
//
#import <Bolts/Bolts.h>
#import "PFRESTFileUploadController.h"
#import "PFRESTFileCommand.h"
#import "PFCommandRunning.h"
#import "PFCommandResult.h"

@implementation PFRESTFileUploadController

-(BFTask<PFFileUploadResult *> * _Nonnull)uploadSourceFilePath:(NSString * _Nonnull)sourceFilePath
                                                      fileName:(NSString * _Nullable)fileName
                                                      mimeType:(NSString * _Nullable)mimeType
                                                  sessionToken:(NSString * _Nonnull)sessionToken
                                             cancellationToken:(BFCancellationToken * _Nonnull)cancellationToken
                                                fileController:(PFFileController *_Nonnull)fileController
                                                 progressBlock:(PFProgressBlock _Nonnull)progressBlock
{
    BFTaskCompletionSource *tcs = [BFTaskCompletionSource taskCompletionSource];
    PFRESTFileCommand *command = [PFRESTFileCommand uploadCommandForFileWithName:fileName sessionToken:sessionToken];
    [[fileController.dataSource.commandRunner runFileUploadCommandAsync:command
                                              withContentType:mimeType
                                        contentSourceFilePath:sourceFilePath
                                                      options:PFCommandRunningOptionRetryIfFailed
                                            cancellationToken:cancellationToken
                                                progressBlock:progressBlock]
         continueWithSuccessBlock:^id(BFTask<PFCommandResult *> *task) {
            if (!task.error) {
                PFCommandResult *result = task.result;
                PFFileUploadResult *uploadResult = [[PFFileUploadResult alloc]init];
                uploadResult.url = result.result[@"url"];
                uploadResult.name = result.result[@"name"];
                [tcs setResult:uploadResult];
            } else {
                [tcs setError:task.error];
            }
            return nil;
        }];
    return tcs.task;
}
@end
