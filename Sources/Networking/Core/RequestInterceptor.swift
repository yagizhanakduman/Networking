//
//  RequestInterceptor.swift
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

// MARK: - Request Interceptor

/// A protocol for intercepting and modifying network requests before execution,
/// and handling retries in case of failures.
///
/// `RequestInterceptor` provides a way to:
/// - **Modify outgoing requests** (e.g., add authentication headers, modify parameters).
/// - **Implement retry policies** for failed requests, including delay-based retries.
///
/// - Methods:
///   - `adapt(_:)`: Modifies an outgoing request before execution, such as adding authentication tokens.
///   - `retry(_:dueTo:currentRetryCount:)`: Determines whether a failed request should be retried.
///
/// - Example Usage:
///   ```swift
///   struct AuthInterceptor: RequestInterceptor {
///       func adapt(_ request: URLRequest) async throws -> URLRequest {
///           var adaptedRequest = request
///           adaptedRequest.addValue("Bearer my_access_token", forHTTPHeaderField: "Authorization")
///           return adaptedRequest
///       }
///
///       func retry(_ request: URLRequest, dueTo error: NetworkError, currentRetryCount: Int) async throws -> RetryResult {
///           return currentRetryCount < 3 ? .retryWithDelay(2.0) : .doNotRetry
///       }
///   }
///   ```
public protocol RequestInterceptor {
    
    /// Modifies an outgoing `URLRequest` before it is sent.
    ///
    /// - Purpose:
    ///   - This method allows modifications such as:
    ///     - Adding **authentication tokens** (e.g., OAuth Bearer tokens).
    ///     - Injecting **custom headers** (e.g., API keys, User-Agent).
    ///     - Transforming **URL parameters** or **body content** before sending.
    ///
    /// - Parameter request: The original `URLRequest` before adaptation.
    ///
    /// - Returns: A modified `URLRequest` containing necessary adaptations.
    ///
    /// - Throws: Throws an error if adaptation fails.
    ///
    /// - Example:
    ///   ```swift
    ///   func adapt(_ request: URLRequest) async throws -> URLRequest {
    ///       var modifiedRequest = request
    ///       modifiedRequest.addValue("Bearer some_token", forHTTPHeaderField: "Authorization")
    ///       return modifiedRequest
    ///   }
    ///   ```
    func adapt(_ request: URLRequest) async throws -> URLRequest
    
    /// Determines whether a request should be retried after a failure.
    ///
    /// - Purpose:
    ///   - This method provides logic to decide:
    ///     - **When to retry** a failed request.
    ///     - **How many retry attempts** should be made before giving up.
    ///     - **Whether to introduce a delay** (e.g., exponential backoff).
    ///
    /// - Parameters:
    ///   - request: The failed `URLRequest` that needs retry evaluation.
    ///   - error: The `NetworkError` that caused the failure.
    ///   - currentRetryCount: The number of retries already attempted.
    ///
    /// - Returns: A `RetryResult` indicating whether to:
    ///   - **Retry immediately** (`.retry`).
    ///   - **Retry after a delay** (`.retryWithDelay(seconds)`).
    ///   - **Use exponential backoff** (`.retryWithExponentialBackoff(config)`).
    ///   - **Stop retrying** (`.doNotRetry`).
    ///
    /// - Throws: Throws an error if retry handling fails.
    ///
    /// - Example:
    ///   ```swift
    ///   func retry(_ request: URLRequest, dueTo error: NetworkError, currentRetryCount: Int) async throws -> RetryResult {
    ///       if currentRetryCount >= 3 { return .doNotRetry }
    ///       return .retryWithExponentialBackoff(ExponentialBackoff(baseDelay: 1.0, backoffBase: 2.0))
    ///   }
    ///   ```
    func retry(_ request: URLRequest, dueTo error: NetworkError, currentRetryCount: Int) async throws -> RetryResult
    
}
