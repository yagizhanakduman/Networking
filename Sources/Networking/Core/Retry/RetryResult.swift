//
//  RetryResult.swift
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

// MARK: - Retry Result

/// Represents the result of a retry decision when a network request fails.
///
/// This enum is used by `RequestInterceptor` to determine whether a failed request
/// should be retried, retried with a delay, or not retried at all.
///
/// - Cases:
///   - `doNotRetry`: The request should not be retried.
///   - `retry`: The request should be retried immediately.
///   - `retryWithDelay(TimeInterval)`: The request should be retried after a specified delay (in seconds).
///   - `retryWithExponentialBackoff(ExponentialBackoff)`:
///     The request should be retried using an exponential backoff strategy
///
/// - Example Usage:
///   ```swift
///   func retry(_ request: URLRequest, dueTo error: NetworkError, currentRetryCount: Int) async throws -> RetryResult {
///       if currentRetryCount >= 3 {
///           return .doNotRetry
///       } else {
///           return .retryWithExponentialBackoff(ExponentialBackoff(baseDelay: 1.0, backoffBase: 2.0))
///       }
///   }
///   ```
public enum RetryResult {
    
    /// The request should not be retried.
    case doNotRetry

    /// The request should be retried immediately.
    case retry

    /// The request should be retried after a specified delay.
    ///
    /// - Parameter delay: The time interval (in seconds) before retrying.
    case retryWithDelay(TimeInterval)

    /// The request should be retried using an exponential backoff strategy.
    ///
    /// - Parameters:
    ///   - backoff: The exponential backoff configuration used to determine retry delays.
    case retryWithExponentialBackoff(ExponentialBackoff)
}
