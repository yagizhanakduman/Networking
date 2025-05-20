//
//  RequestConfig.swift
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

// MARK: - Request Config

/// A configuration struct for defining the details of a network request.
///
/// `RequestConfig` encapsulates all necessary components for making a request,
/// including the URL, HTTP method, parameters, headers, and an optional user identifier.
///
/// - Properties:
///   - `url`: The `URL` to which the request will be sent.
///   - `method`: The `HTTPMethod` to be used for the request. Defaults to `.get`.
///   - `queryParameters`: Optional dictionary of query parameters to be appended to the URL.
///   - `bodyParameters`: Optional dictionary of body parameters to be included in the request body.
///   - `headers`: Optional `HTTPHeaders` containing custom headers for the request.
///   - `userID`: An optional identifier specifying which user session the request belongs to.
///
/// - Example:
///   ```swift
///   let config = RequestConfig(
///       url: URL(string: "https://api.example.com/user")!,
///       method: .post,
///       bodyParameters: ["name": "John Doe", "email": "john@example.com"],
///       headers: HTTPHeaders(["Authorization": "Bearer token"]),
///       userID: "12345"
///   )
///   ```
public struct RequestConfig {
    
    /// The URL `String` to which the request will be sent.
    /// The URL string representing the endpoint to which the request will be sent.
    /// This is the **base URL** for the network request.
    public let url: String
    
    /// The HTTP method to be used for the request.
    /// Determines whether the request is `GET`, `POST`, `PUT`, `DELETE`, etc.
    /// Defaults to `.get`.
    public let method: HTTPMethod
    
    /// Optional query parameters that will be appended to the URL.
    /// Example: `{ "page": 1, "limit": 20 }` → `?page=1&limit=20`
    /// **Used for GET requests to pass filtering, pagination, or sorting parameters.**
    public let queryParameters: Parameters?
    
    /// Optional dictionary of body parameters that will be included in the request body.
    /// **Only applicable for `POST`, `PUT`, and `PATCH` requests.**
    /// Example:
    /// ```swift
    /// bodyParameters: ["name": "Alice", "age": 25]
    /// ```
    /// This will be JSON-encoded and sent as the request body.
    public let bodyParameters: Parameters?
    
    /// Optional headers for the request.
    /// Headers include authentication tokens, content types, and other metadata.
    /// Example:
    /// ```swift
    /// headers: ["Authorization": "Bearer abc123", "Content-Type": "application/json"]
    /// ```
    public let headers: HTTPHeaders?
    
    /// An optional identifier for the user session.
    /// If the request is tied to a specific user, this can be used to attach
    /// authentication tokens dynamically from a session provider.
    public let userID: String?
    
    /// Initializes a `RequestConfig` with the given parameters.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP method to use. Defaults to `.get`.
    ///   - queryParameters: Optional query parameters for the request.
    ///   - bodyParameters: Optional body parameters for the request.
    ///   - headers: Optional headers for the request.
    ///   - userID: An optional identifier for the user session.
    public init(url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, userID: String? = nil) {
        self.url = url
        self.method = method
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.headers = headers
        self.userID = userID
    }
    
}
