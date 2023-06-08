/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

/**
 * Add support for both SPM and Dynamic Framework Imports TODO: (@dplewis)
 */
#if canImport(ParseCore)
    @_exported import ParseCore
#else
    @_exported import Parse
#endif
