/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

/**
 Namespace struct for all errors reported by the Live Query SDK.
 */
public struct LiveQueryErrors {
    fileprivate init() {}

    /**
     An error that is reported when the server returns a response that cannot be parsed.
     */
    public struct InvalidResponseError: Error {
        /// Response string of the error.
        public let response: String
    }

    /**
     An error that is reported when the server does not accept a query we've sent to it.
     */
    public struct InvalidQueryError: Error {
    }

    /**
     An error that is reported when the server returns valid JSON, but it doesn't match the format we expect.
     */
    public struct InvalidJSONError: Error {
        /// JSON used for matching.
        public let json: [String:AnyObject]
        /// Key that was expected to match.
        public let expectedKey: String
    }

    /**
     An error that is reported when the server returns valid JSON, but it doesn't match the format we expect.
     */
    public struct InvalidJSONObject: Error {
        /// JSON used for matching.
        public let json: [String:AnyObject]
        /// Details about the error
        public let details: String
    }

    /**
     An error that is reported when the live query server encounters an internal error.
     */
    public struct ServerReportedError: Error {
        /// Error code reported by the server.
        public let code: Int
        /// String error reported by the server.
        public let error: String
        /// Boolean value representing whether a client should reconnect.
        public let reconnect: Bool
    }
}
