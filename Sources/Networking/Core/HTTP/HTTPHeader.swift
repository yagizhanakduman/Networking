//
//  HTTPHeader.swift
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

// MARK: - HTTPHeader

/// Represents an HTTP header with a name and value.
///
/// HTTP headers are key-value pairs used in HTTP requests and responses
/// to convey metadata such as content type, authorization, and caching policies.
///
/// - Properties:
///   - `name`: The name of the header (e.g., `"Content-Type"`).
///   - `value`: The value of the header (e.g., `"application/json"`).
///
/// - Example:
///   ```swift
///   let contentTypeHeader = HTTPHeader(name: "Content-Type", value: "application/json")
///   ```
public struct HTTPHeader {
    
    /// **The name of the HTTP header.**
    public let name: String
    
    /// **The value of the HTTP header.**
    public let value: String

    /// Initializes an `HTTPHeader` instance.
    ///
    /// - Parameters:
    ///   - name:  The name of the header.
    ///   - value: The value of the header.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
}

// MARK: - Default Headers
extension HTTPHeader {
    
    /// Returns an `Accept` header.
    ///
    /// - Parameter value: The `Accept` value.
    /// - Returns:         The header.
    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }
    
    /// Returns an `Accept-Charset` header.
    ///
    /// - Parameter value: The `Accept-Charset` value.
    /// - Returns:         The header.
    public static func acceptCharset(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Charset", value: value)
    }

    /// Returns an `Accept-Language` header.
    ///
    /// Default Accept-Language header that accumulates and encodes the system's preferred languages.
    /// Use `HTTPHeader.defaultAcceptLanguage`.
    ///
    /// - Parameter value: The `Accept-Language` value.
    ///
    /// - Returns:         The header.
    public static func acceptLanguage(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Language", value: value)
    }

    /// Returns an `Accept-Encoding` header.
    ///
    /// A default accept encoding value that provides the most common values. Use
    /// `HTTPHeader.defaultAcceptEncoding`.
    ///
    /// - Parameter value: The `Accept-Encoding` value.
    ///
    /// - Returns:         The header
    public static func acceptEncoding(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Encoding", value: value)
    }

    /// Returns a `Basic` `Authorization` header using the `username` and `password` provided.
    ///
    /// - Parameters:
    ///   - username: The username of the header.
    ///   - password: The password of the header.
    ///
    /// - Returns:    The header.
    public static func authorization(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return authorization("Basic \(credential)")
    }

    /// Returns a `Bearer` `Authorization` header using the `bearerToken` provided.
    ///
    /// - Parameter bearerToken: The bearer token.
    ///
    /// - Returns:               The header.
    public static func authorization(bearerToken: String) -> HTTPHeader {
        authorization("Bearer \(bearerToken)")
    }

    /// Returns an `Authorization` header.
    ///
    /// Provides built-in methods to produce `Authorization` headers. For a Basic `Authorization` header use
    /// `HTTPHeader.authorization(username:password:)`. For a Bearer `Authorization` header, use
    /// `HTTPHeader.authorization(bearerToken:)`.
    ///
    /// - Parameter value: The `Authorization` value.
    ///
    /// - Returns:         The header.
    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: value)
    }

    /// Returns a `Content-Disposition` header.
    ///
    /// - Parameter value: The `Content-Disposition` value.
    ///
    /// - Returns:         The header.
    public static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Disposition", value: value)
    }

    /// Returns a `Content-Encoding` header.
    ///
    /// - Parameter value: The `Content-Encoding`.
    ///
    /// - Returns:         The header.
    public static func contentEncoding(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Encoding", value: value)
    }

    /// Returns a `Content-Type` header.
    ///
    /// Set the `Content-Type` of the request, so it may not
    /// be necessary to manually set this value.
    ///
    /// - Parameter value: The `Content-Type` value.
    ///
    /// - Returns:         The header.
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    /// Returns a `User-Agent` header.
    ///
    /// - Parameter value: The `User-Agent` value.
    ///
    /// - Returns:         The header.
    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
    }
    
}

// MARK: - HTTPHeader Collection Extensions
extension [HTTPHeader] {
    
    /// **Finds the index** of an `HTTPHeader` by its name (case-insensitive).
    ///
    /// - Parameter name: The **header name** to search for.
    /// - Returns: The **index of the header** in the array, or `nil` if not found.
    ///
    /// - Example:
    ///   ```swift
    ///   let headers: [HTTPHeader] = [
    ///       .contentType("application/json"),
    ///       .authorization(bearerToken: "myToken")
    ///   ]
    ///
    ///   if let index = headers.index(of: "Authorization") {
    ///       print("Authorization header found at index: \(index)")
    ///   }
    ///   ```
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }
    
}
