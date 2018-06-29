/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef PFTwitterLocalization_h
#define PFTwitterLocalization_h

#define PFTWLocalizedString(key, comment) \
[[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:@"ParseTwitterUtils"]

#endif
