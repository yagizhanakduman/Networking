//
//  StatusCodeType.swift
//  Networking
//
//  MIT License
//
//  Copyright (c) 2025 Networking - Yağızhan Akduman
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

// MARK: - Status Code Type

/// Represents the type of an HTTP status code.
///
/// HTTP status codes are categorized into different types based on their numeric range.
/// This enum helps classify status codes for easier handling in network responses.
///
/// - Cases:
///   - `informational`: Status codes **(100–199)** indicating an **informational response**.
///   - `successful`: Status codes **(200–299)** indicating a **successful request**.
///   - `redirection`: Status codes **(300–399)** indicating a **redirection response**.
///   - `clientError`: Status codes **(400–499)** indicating a **client-side error**.
///   - `serverError`: Status codes **(500–599)** indicating a **server-side error**.
///   - `cancelled`: Represents a **cancelled request**, typically caused by user intervention or a timeout.
///   - `unknown`: Represents an **undefined or unexpected** status code.
///
/// - Example Usage:
///   ```swift
///   let statusCode = 404
///   print(statusCode.statusCodeType) // Outputs: clientError
///   ```
///
/// - Reference:
///   - [MDN Web Docs - HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
public enum StatusCodeType {
    
    /// Status codes (100–199) indicating an **informational response**.
    case informational
    
    /// Status codes (200–299) indicating a **successful request**.
    case successful
    
    /// Status codes (300–399) indicating a **redirection response**.
    case redirection
    
    /// Status codes (400–499) indicating a **client-side error**.
    case clientError
    
    /// Status codes (500–599) indicating a **server-side error**.
    case serverError
    
    /// Represents a **cancelled request**, typically caused by user intervention or a timeout.
    case cancelled
    
    /// Represents an **undefined or unexpected** status code.
    case unknown
}

// MARK: - HTTP Status Code Classification Extension
public extension Int {
    
    /// Categorizes an HTTP status code into a `StatusCodeType`.
    ///
    /// This computed property helps classify HTTP status codes into predefined categories,
    /// making it easier to handle responses based on their type.
    ///
    /// - Returns: A `StatusCodeType` representing the type of the status code.
    ///
    /// - Example:
    ///   ```swift
    ///   let statusCode = 404
    ///   print(statusCode.statusCodeType) /// Output: .clientError
    ///   ```
    ///
    /// - Note:
    ///   - Includes `URLError.cancelled.rawValue` to specifically classify cancelled requests.
    ///   - Covers all standard HTTP status code ranges as defined in RFC 7231.
    var statusCodeType: StatusCodeType {
        if self == URLError.cancelled.rawValue {
            return .cancelled
        }
        switch self {
        case 100..<200:
            return .informational
        case 200..<300:
            return .successful
        case 300..<400:
            return .redirection
        case 400..<500:
            return .clientError
        case 500..<600:
            return .serverError
        default:
            return .unknown
        }
    }
    
}
