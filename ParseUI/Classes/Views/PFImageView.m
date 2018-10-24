/*
 *  Copyright (c) 2014, Parse, LLC. All rights reserved.
 *
 *  You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 *  copy, modify, and distribute this software in source code or binary form for use
 *  in connection with the web services and APIs provided by Parse.
 *
 *  As with any software that integrates with the Parse platform, your use of
 *  this software is subject to the Parse Terms of Service
 *  [https://www.parse.com/about/terms]. This copyright notice shall be
 *  included in all copies or substantial portions of the software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "PFImageView.h"

#import <Bolts/BFTaskCompletionSource.h>

#import <Parse/PFFileObject.h>

#import "PFImageCache.h"

@implementation PFImageView

#pragma mark -
#pragma mark Accessors

- (void)setFile:(PFFileObject *)otherFile {
    // Here we don't check (file != otherFile)
    // because self.image needs to be updated regardless.
    // setFile: could have altered self.image
    _file = otherFile;
    NSURL *url = [NSURL URLWithString:self.file.url];
    UIImage *cachedImage = [[PFImageCache sharedCache] imageForURL:url];
    if (cachedImage) {
        self.image = cachedImage;
    }
}

#pragma mark -
#pragma mark Load

- (BFTask<UIImage *> *)loadInBackground {
    BFTaskCompletionSource<UIImage *> *source = [BFTaskCompletionSource taskCompletionSource];
    [self loadInBackground:^(UIImage *image, NSError *error) {
        if (error) {
            [source trySetError:error];
        } else {
            [source trySetResult:image];
        }
    }];
    return source.task;
}


- (void)loadInBackground:(void (^)(UIImage *, NSError *))completion {
    [self loadInBackground:completion progressBlock:nil];
}

- (void)loadInBackground:(void (^)(UIImage *, NSError *))completion progressBlock:(PFProgressBlock)progressBlock {
    if (!self.file) {
        // When there is nothing to load, the user just wants to display
        // the placeholder image. I think the better design decision is
        // to return with no error, to simplify caller logic. (arguable)
        if (completion) {
            completion(nil, nil);
        }
        return;
    }

    if (!self.file.url) {
        // The file has not been saved.
        if (completion) {
            NSError *error = [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorUnsavedFile userInfo:nil];
            completion(nil, error);
        }
        return;
    }

    NSURL *url = [NSURL URLWithString:self.file.url];
    if (url) {
        UIImage *cachedImage = [[PFImageCache sharedCache] imageForURL:url];
        if (cachedImage) {
            self.image = cachedImage;

            if (progressBlock) {
                progressBlock(100);
            }
            if (completion) {
                completion(cachedImage, nil);
            }
            return;
        }
    }


    PFFileObject *file = _file;
    [_file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
            return;
        }

        // We dispatch to a background queue to offload the work to decode data into image
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            if (!image) {
                if (completion) {
                    NSError *invalidDataError = [NSError errorWithDomain:PFParseErrorDomain
                                                                    code:kPFErrorInvalidImageData
                                                                userInfo:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, invalidDataError);
                    });
                }
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                // check if a latter issued loadInBackground has not replaced the file being loaded
                if (file == self->_file) {
                    self.image = image;
                }

                if (completion) {
                    completion(image, nil);
                }
            });

            if (url) {
                // We always want to store the image in the cache.
                // In previous checks we've verified neither key nor value is nil.
                [[PFImageCache sharedCache] setImage:image forURL:url];
            }
        });
    } progressBlock:progressBlock];
}

@end
