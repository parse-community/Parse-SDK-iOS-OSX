//
//  PFFileUploadResult.h
//  Parse
//
//  Created by Ken Cooper on 2/21/17.
//  Copyright © 2017 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Response provided by a custom `PFFileUploadController`.
 */
@interface PFFileUploadResult : NSObject
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *name;
@end
