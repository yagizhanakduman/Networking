//
//  RetryStrategy.swift
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

// MARK: - Retry Strategy

/// Defines a strategy for determining whether a failed network request should be retried.
///
/// Implementations of `RetryStrategy` provide logic to decide when and how
/// to retry a request based on the encountered `NetworkError` and the current retry count.
///
/// - Methods:
///   - `decide(error:currentRetryCount:)`: Determines the retry behavior for a given error and retry attempt count.
///   - `maxRetries`: Specifies the maximum number of allowed retries before giving up.
///
/// - Example Usage:
///   ```swift
///   struct DefaultRetryStrategy: RetryStrategy {
///       let maxRetries = 3
///
///       func decide(error: NetworkError, currentRetryCount: Int) -> RetryResult {
///           return currentRetryCount < maxRetries ? .retryWithDelay(2.0) : .doNotRetry
///       }
///   }
///   ```
public protocol RetryStrategy {
    
    /// The maximum number of retries before stopping.
    ///
    /// - Note: Implementations should define this to limit excessive retries.
    var maxRetries: Int { get }

    /// Determines whether a request should be retried based on the error and retry count.
    ///
    /// - Parameters:
    ///   - error: The `NetworkError` that caused the failure.
    ///   - currentRetryCount: The number of retries already attempted.
    /// - Returns: A `RetryResult` indicating whether to retry, delay, or stop retrying.
    func decide(error: NetworkError, currentRetryCount: Int) -> RetryResult
}
