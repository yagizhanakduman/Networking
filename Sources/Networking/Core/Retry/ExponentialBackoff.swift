//
//  ExponentialBackoff.swift
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

// MARK: - Exponential Backoff

/// A utility for calculating exponential backoff delays for retrying network requests.
///
/// Exponential backoff is a retry strategy that progressively increases the delay between retry attempts,
/// helping to prevent **server overload** and **rate-limiting issues**.
///
/// - Properties:
///   - `baseDelay`: The initial delay before the first retry, in seconds. Defaults to `1.0`.
///   - `backoffBase`: The multiplier used to calculate the exponential delay. Defaults to `2.0`.
///   - `maxDelay`: An optional **maximum** delay cap to prevent excessively long waits.
///
/// - Methods:
///   - `delay(for retryCount: Int) -> TimeInterval`: Computes the delay for a given retry attempt.
///
/// - Example Usage:
///   ```swift
///   let backoff = ExponentialBackoff(baseDelay: 1.0, backoffBase: 2.0, maxDelay: 30.0)
///   print(backoff.delay(for: 0)) /// 1.0 seconds
///   print(backoff.delay(for: 1)) /// 2.0 seconds
///   print(backoff.delay(for: 2)) /// 4.0 seconds
///   print(backoff.delay(for: 5)) /// 32.0 seconds (but capped at 30.0)
///   ```
public struct ExponentialBackoff {
    
    /// The initial delay before the first retry, in seconds.
    public let baseDelay: TimeInterval
    
    /// The multiplier used to calculate the exponential delay.
    public let backoffBase: Double
    
    /// An optional maximum delay cap to **prevent excessively long wait times**.
    public let maxDelay: TimeInterval?
    
    /// Initializes an `ExponentialBackoff` instance.
    ///
    /// - Parameters:
    ///   - baseDelay: The starting delay for retries. Defaults to `1.0` second.
    ///   - backoffBase: The multiplier for exponential growth. Defaults to `2.0`.
    ///   - maxDelay: An optional maximum delay cap. If `nil`, no cap is applied.
    public init(baseDelay: TimeInterval = 1.0, backoffBase: Double = 2.0, maxDelay: TimeInterval? = nil) {
        self.baseDelay = baseDelay
        self.backoffBase = backoffBase
        self.maxDelay = maxDelay
    }
    
    /// Computes the delay for a given retry count using an exponential backoff formula.
    ///
    /// - Parameter retryCount: The current retry attempt (starting from `0`).
    /// - Returns: The computed delay in seconds, capped at `maxDelay` if specified.
    ///
    /// - Example:
    ///   ```swift
    ///   let delay = backoff.delay(for: 3) /// 8.0 seconds (1 * 2^3)
    ///   ```
    public func delay(for retryCount: Int) -> TimeInterval {
        let computedDelay = baseDelay * pow(backoffBase, Double(retryCount))
        return maxDelay.map { min(computedDelay, $0) } ?? computedDelay
    }
    
}
