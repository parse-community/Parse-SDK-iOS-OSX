//
//  PFAppleAuthenticationProvider.m
//  ParseUIDemo
//
//  Created by Darren Black on 20/12/2019.
//  Copyright © 2019 Parse Inc. All rights reserved.
//

#import "PFAppleAuthenticationProvider.h"

@implementation PFAppleAuthenticationProvider

- (BOOL)restoreAuthenticationWithAuthData:(nullable NSDictionary<NSString *,NSString *> *)authData {
    return authData[@"id"] != nil;
}

@end
