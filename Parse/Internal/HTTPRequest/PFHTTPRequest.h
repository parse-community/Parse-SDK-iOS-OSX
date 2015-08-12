/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef Parse_PFHTTPRequest_h
#define Parse_PFHTTPRequest_h

#import <Foundation/Foundation.h>

static NSString *const PFHTTPRequestMethodGET = @"GET";
static NSString *const PFHTTPRequestMethodHEAD = @"HEAD";
static NSString *const PFHTTPRequestMethodDELETE = @"DELETE";
static NSString *const PFHTTPRequestMethodPOST = @"POST";
static NSString *const PFHTTPRequestMethodPUT = @"PUT";

static NSString *const PFHTTPRequestHeaderNameContentType = @"Content-Type";
static NSString *const PFHTTPRequestHeaderNameContentLength = @"Content-Length";

#endif
