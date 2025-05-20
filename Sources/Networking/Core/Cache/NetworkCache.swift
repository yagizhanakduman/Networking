//
//  NetworkCache.swift
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

/// A simple in-memory cache for storing network responses.
///
/// `NetworkCache` implements `ResponseCaching` to provide thread-safe caching of network responses,
/// allowing retrieval and optional expiration of cached data. This cache is useful for temporarily
/// storing API responses to reduce redundant network calls and improve performance.
///
/// - Features:
///   - **Thread Safety**: Uses a serial `DispatchQueue` to synchronize access to the cache.
///   - **Expiration Support**: Allows setting expiration times for cached data.
///   - **Lightweight In-Memory Storage**: Does not persist data to disk.
///
/// - Use Cases:
///   - **Speed Optimization**: Retrieve frequently requested data without hitting the network.
///   - **Offline Access**: Provide cached responses when there’s no active internet connection.
///   - **Rate Limiting**: Reduce unnecessary API calls by storing temporary responses.
///
/// - Properties:
///   - `storage`: A dictionary storing cached responses mapped by their request URLs.
///   - `queue`: A serial dispatch queue ensuring thread-safe access to `storage`.
///
/// - Example Usage:
///   ```swift
///   let cache = NetworkCache()
///   let data = "Sample Response".data(using: .utf8)!
///   let url = URL(string: "https://api.example.com/data")!
///   cache.setResponse(data, for: url, expireTime: Date().addingTimeInterval(3600)) // Cache for 1 hour
///
///   if let cachedData = cache.getResponse(for: url) {
///       print("Retrieved cached response:", String(data: cachedData, encoding: .utf8)!)
///   }
///   ```
public class NetworkCache: ResponseCaching {
    
    /// Represents a cached item containing the response data and an optional expiration date.
    ///
    /// - `data`: The raw response data stored in the cache.
    /// - `expireTime`: An optional expiration date. If `nil`, the data never expires.
    private struct CacheItem {
        let data: Data
        let expireTime: Date?
    }
    
    /// A dictionary storing cached responses, keyed by `URL`.
    ///
    /// - Key: The `URL` of the request.
    /// - Value: A `CacheItem` containing the response data and expiration time.
    private var storage: [URL: CacheItem] = [:]
    
    /// A serial dispatch queue ensuring **thread-safe** access to the cache.
    ///
    /// - Note: This prevents race conditions when modifying `storage` in multi-threaded environments.
    private let queue = DispatchQueue(label: "networking.networkCache.lock")
    
    /// Initializes an empty `NetworkCache` instance.
    ///
    /// - Note: This cache is **only in-memory** and does not persist data across app launches.
    public init() {}
    
    /// Retrieves a cached response for a given URL, if available and not expired.
    ///
    /// - Parameter url: The `URL` whose response should be retrieved.
    /// - Returns: The cached response `Data` if available and valid, otherwise `nil`.
    ///
    /// - Note:
    ///   - If the cached data has expired, it is automatically removed from the cache.
    ///   - This function is **thread-safe** and executes synchronously on `queue.sync`.
    ///
    /// - Example:
    ///   ```swift
    ///   if let cachedData = cache.getResponse(for: url) {
    ///       print("Using cached response:", String(data: cachedData, encoding: .utf8)!)
    ///   } else {
    ///       print("No valid cached response available.")
    ///   }
    ///   ```
    public func getResponse(for url: URL) -> Data? {
        queue.sync {
            guard let item = storage[url] else {
                return nil
            }
            if let expireTime = item.expireTime, expireTime < Date() {
                storage.removeValue(forKey: url) // Remove expired item
                return nil
            }
            return item.data
        }
    }
    
    /// Stores a response in the cache with an optional expiration date.
    ///
    /// - Parameters:
    ///   - data: The response data to be cached.
    ///   - url: The `URL` associated with the cached response.
    ///   - expireTime: An optional expiration date after which the cache entry becomes invalid.
    ///
    /// - Note:
    ///   - If `expireTime` is `nil`, the data is stored indefinitely (until manually cleared).
    ///   - This function is **thread-safe** and executes synchronously on `queue.sync`.
    ///
    /// - Example:
    ///   ```swift
    ///   let response = "API Response".data(using: .utf8)!
    ///   let expireTime = Date().addingTimeInterval(1800) // 30 minutes cache
    ///   cache.setResponse(response, for: url, expireTime: expireTime)
    ///   ```
    public func setResponse(_ data: Data, for url: URL, expireTime: Date?) {
        queue.sync {
            let item = CacheItem(data: data, expireTime: expireTime)
            storage[url] = item
        }
    }
    
    /// Clears all cached responses.
    ///
    /// - Note:
    ///   - This function removes **all cached data**, regardless of expiration.
    ///   - Call this method when a user logs out or when you need to reset cached responses.
    ///
    /// - Example:
    ///   ```swift
    ///   cache.clear() // Removes all cached items
    ///   ```
    public func clear() {
        queue.sync {
            storage.removeAll()
        }
    }
    
}
