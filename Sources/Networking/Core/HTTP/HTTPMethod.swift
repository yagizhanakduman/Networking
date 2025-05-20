//
//  HTTPMethod.swift
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

// MARK: - HTTPMethod

/// Represents the HTTP methods used in network requests.
///
/// These methods are defined by [RFC 7231](https://tools.ietf.org/html/rfc7231)
/// and specify the desired action to be performed on a resource.
///
/// - Cases:
///   - `get`: Retrieves data from the server. **Safe** and **idempotent**.
///   - `post`: Submits data to be processed, potentially creating a new resource.
///   - `put`: Updates an existing resource or creates one if it does not exist.
///   - `delete`: Removes a resource from the server.
///   - `connect`: Establishes a tunnel to the server (used in **HTTPS proxies**).
///   - `options`: Retrieves the communication options available for a resource.
///   - `trace`: Performs a loopback test to see how a request travels to a resource.
///   - `patch`: Partially updates an existing resource.
///   - `head`: Similar to `GET`, but only retrieves headers (useful for checking resource validity).
///
/// - Characteristics:
///   | Method  | Idempotent | Cacheable | Safe  | Common Use Case |
///   |----------------|-----------|-----------|----------|----------------|
///   | `GET`          | ✅        | ✅        | ✅   | Fetching data  |
///   | `POST`        | ❌        | ❌        | ❌   | Submitting forms, creating data  |
///   | `PUT`          | ✅         | ❌        | ❌   | Updating a resource |
///   | `DELETE`    | ✅        | ❌        | ❌   | Removing data  |
///   | `PATCH`      | ❌        | ❌        | ❌   | Partially modifying a resource  |
///   | `HEAD`        | ✅        | ✅         | ✅   | Checking if a resource exists  |
///   | `OPTIONS` | ✅         | ❌        | ✅   | Checking supported methods  |
///   | `TRACE`     | ✅         | ❌         | ✅   | Debugging request paths  |
///   | `CONNECT` | ❌         | ❌        | ❌   | Establishing a tunnel  |
///
/// - Example Usage:
///   ```swift
///   let method: HTTPMethod = .post
///   print(method.rawValue) // "POST"
///
///   if method == .get {
///       print("Performing a GET request")
///   }
///   ```
///
/// - Best Practices:
///   - Use **`GET`** for fetching data; avoid using it for actions that modify server state.
///   - Use **`POST`** for submitting sensitive data and transactions.
///   - Use **`PUT`** when replacing or updating an entire resource.
///   - Use **`PATCH`** for **partial updates** rather than full replacements.
///   - Use **`DELETE`** only when absolutely necessary, and be cautious of its impact.
public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace   = "TRACE"
    case patch   = "PATCH"
    case head    = "HEAD"
}
