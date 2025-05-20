//
//  CachePolicy.swift
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

/// A model representing caching preferences for network requests.
///
/// `CachePolicy` defines how network responses should interact with caching:
/// - Whether to retrieve a response from cache if available.
/// - Whether to store a new response in the cache.
/// - An optional expiration date for cached responses.
///
/// - Features:
///   - **Fine-Grained Control**: Customize caching behavior per request.
///   - **Expiration Handling**: Define a specific expiration date for cached data.
///   - **Performance Optimization**: Reduces redundant network calls when cache is enabled.
///
/// - Use Cases:
///   - **Offline Mode**: Use cached responses when offline.
///   - **Performance Optimization**: Reduce unnecessary API calls by caching frequently accessed data.
///   - **Temporary Caching**: Store short-lived responses to improve speed while ensuring freshness.
///
/// - Properties:
///   - `useCache`: A Boolean indicating whether to retrieve responses from the cache if available.
///   - `storeCache`: A Boolean indicating whether to store the response in the cache.
///   - `expireTime`: An optional `Date` specifying when the cached response should expire.
///
/// - Example Usage:
///   ```swift
///   /// Example: Store API response in cache for 1 hour
///   let cacheConfig = CachePolicy(useCache: true, storeCache: true, expireTime: Date().addingTimeInterval(3600))
///   ```
public struct CachePolicy {
    
    /// Determines whether the cached response should be used when available.
    ///
    /// - `true`: If a cached response exists, it will be used instead of making a new network request.
    /// - `false`: Always make a network request, even if a cached response is available.
    public let useCache: Bool
    
    /// Determines whether the response should be stored in the cache.
    ///
    /// - `true`: The response will be saved in the cache after retrieval.
    /// - `false`: The response will not be stored.
    public let storeCache: Bool
    
    /// The expiration time of the cached response.
    ///
    /// - If `nil`, the cache does not expire, and the response remains valid indefinitely.
    /// - If a `Date` is provided, the cache will expire at that time.
    public let expireTime: Date?
    
    /// Initializes a `CachePolicy` with the given caching preferences.
    ///
    /// - Parameters:
    ///   - useCache: Whether to retrieve cached responses. Defaults to `false`.
    ///   - storeCache: Whether to store responses in the cache. Defaults to `false`.
    ///   - expireTime: The expiration date for the cached response. Defaults to `nil` (no expiration).
    ///
    /// - Example:
    ///   ```swift
    ///   /// Enable cache usage but do not store new responses
    ///   let cachePolicy = CachePolicy(useCache: true, storeCache: false)
    ///
    ///   /// Store responses and use them for up to 24 hours
    ///   let cachePolicy = CachePolicy(useCache: true, storeCache: true, expireTime: Date().addingTimeInterval(86400))
    ///   ```
    public init(useCache: Bool = false, storeCache: Bool = false, expireTime: Date? = nil) {
        self.useCache = useCache
        self.storeCache = storeCache
        self.expireTime = expireTime
    }
    
}
