/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileState.h"
#import "PFFileState_Private.h"

#import "PFMutableFileState.h"
#import "PFPropertyInfo.h"

static NSString *const _PFFileStateSecureDomain = @"files.parsetfss.com";

@interface PFFileState ()

@property (nonatomic, copy, readwrite) NSString *secureURLString;

@end

@implementation PFFileState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{
        @"name" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"urlString" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"mimeType" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
    };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFFileState *)state {
    return [super initWithState:state];
}

- (instancetype)initWithName:(NSString *)name urlString:(NSString *)urlString mimeType:(NSString *)mimeType {
    self = [super init];
    if (!self) return nil;

    _name = (name ? [name copy] : @"file");
    _urlString = [urlString copy];
    _mimeType = [mimeType copy];

    return self;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setUrlString:(NSString *)urlString {
    if (self.urlString != urlString) {
        _urlString = [urlString copy];
        _secureURLString = nil; // Invalidate variable cache
    }
}

- (NSString *)secureURLString {
    if (_secureURLString) {
        return _secureURLString;
    }

    if (!self.urlString) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:self.urlString];
    if (!components) {
        return self.urlString;
    }

    NSString *scheme = components.scheme;
    if (![scheme isEqualToString:@"http"]) {
        return self.urlString;
    }

    if ([components.host isEqualToString:_PFFileStateSecureDomain]) {
        components.scheme = @"https";
    }
    _secureURLString = components.URL.absoluteString;
    return _secureURLString;
}

///--------------------------------------
#pragma mark - Mutable Copying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFFileState allocWithZone:zone] initWithState:self];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableFileState allocWithZone:zone] initWithState:self];
}

@end
