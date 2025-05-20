//
//  ResponseCaching.swift
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

/// A protocol for handling response caching in network requests.
///
/// `ResponseCaching` provides methods to store, retrieve, and clear cached responses,
/// helping to improve performance and reduce unnecessary network requests.
/// This is particularly useful in applications that make frequent API calls where
/// responses do not change often.
///
/// - Features:
///   - **Performance Optimization**: Avoids redundant network requests by caching responses.
///   - **Expiration Control**: Allows responses to have a defined expiration time.
///   - **Memory Management**: Implementations can choose in-memory, disk-based, or hybrid caching.
///
/// - Use Cases:
///   - **Fast API Response**: Cache frequently requested API responses for quick retrieval.
///   - **Offline Mode**: Provide cached responses when there’s no internet connection.
///   - **Efficient Rate Limiting**: Reduce excessive API calls by serving cached results.
///
/// - Methods:
///   - `setResponse(_:for:expireTime:)`: Stores a response in the cache with an optional expiration date.
///   - `getResponse(for:) -> Data?`: Retrieves a cached response for a given URL, if available.
///   - `clear()`: Clears all cached responses.
///
/// - Example Usage:
///   ```swift
///   class MemoryResponseCache: ResponseCaching {
///       /// A dictionary storing cached responses mapped by their request URLs.
///       private var cache: [URL: (data: Data, expireTime: Date?)] = [:]
///
///       /// Stores a response in memory cache with an optional expiration time.
///       func setResponse(_ data: Data, for url: URL, expireTime: Date?) {
///           cache[url] = (data, expireTime)
///       }
///
///       /// Retrieves a cached response if it hasn't expired.
///       func getResponse(for url: URL) -> Data? {
///           guard let cached = cache[url] else { return nil }
///           if let expireTime = cached.expireTime, expireTime < Date() {
///               cache.removeValue(forKey: url) // Remove expired item
///               return nil
///           }
///           return cached.data
///       }
///
///       /// Clears all cached responses.
///       func clear() {
///           cache.removeAll()
///       }
///   }
///   ```
public protocol ResponseCaching {
    
    /// Stores a response in the cache with an optional expiration date.
    ///
    /// - Parameters:
    ///   - data: The response data to be cached.
    ///   - url: The `URL` associated with the cached response.
    ///   - expireTime: An optional expiration date after which the cache entry becomes invalid.
    ///
    /// - Note:
    ///   - If `expireTime` is `nil`, the response remains in the cache indefinitely (until manually cleared).
    ///   - Implementations should handle automatic cache eviction for expired entries.
    ///
    /// - Example:
    ///   ```swift
    ///   let expireTime = Date().addingTimeInterval(3600) // 1-hour expiration
    ///   cache.setResponse(responseData, for: requestURL, expireTime: expireTime)
    ///   ```
    func setResponse(_ data: Data, for url: URL, expireTime: Date?)
    
    /// Retrieves a cached response for a given URL, if available and not expired.
    ///
    /// - Parameter url: The `URL` whose response should be retrieved.
    /// - Returns: The cached response `Data` if available and valid, otherwise `nil`.
    ///
    /// - Note:
    ///   - If the cached data has expired, it should be removed automatically.
    ///
    /// - Example:
    ///   ```swift
    ///   if let cachedData = cache.getResponse(for: url) {
    ///       print("Using cached response:", String(data: cachedData, encoding: .utf8)!)
    ///   } else {
    ///       print("Fetching fresh data from API.")
    ///   }
    ///   ```
    func getResponse(for url: URL) -> Data?
    
    /// Clears all cached responses.
    ///
    /// - Note:
    ///   - This removes **all** stored cache entries, including valid ones.
    ///   - Call this method when a user logs out or when fresh data is required.
    ///
    /// - Example:
    ///   ```swift
    ///   cache.clear() // Clears all cached data
    ///   ```
    func clear()
}
