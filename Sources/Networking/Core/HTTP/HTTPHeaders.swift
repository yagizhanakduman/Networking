//
//  HTTPHeaders.swift
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

// MARK: - HTTPHeaders

/// A collection of HTTP headers, allowing case-insensitive updates, additions, and removals.
///
/// This structure maintains a set of `HTTPHeader` objects, ensuring that headers with the same name
/// (case-insensitive) are updated rather than duplicated.
///
/// - Properties:
///   - `headers`: A private array storing the `HTTPHeader` objects.
///
/// - Initializers:
///   - `init()`: Creates an empty instance.
///   - `init(_ headers: [HTTPHeader])`: Initializes with an array of `HTTPHeader`s, merging duplicates.
///   - `init(_ dictionary: [String: String])`: Initializes with a dictionary, merging duplicates.
///
/// - Methods:
///   - `add(name:value:)`: Adds or updates a header by name.
///   - `add(_ header: HTTPHeader)`: Adds or updates a header.
///   - `update(name:value:)`: Updates or appends a header by name.
///   - `update(_ header: HTTPHeader)`: Updates or appends a header.
///   - `remove(name:)`: Removes a header by name.
///   - `dictionary`: Returns all headers as a `[String: String]` dictionary.
///
/// - Example:
///   ```swift
///   var headers = HTTPHeaders()
///   headers.add(name: "Content-Type", value: "application/json")
///   headers.update(name: "Authorization", value: "Bearer token")
///   print(headers.dictionary) // ["Content-Type": "application/json", "Authorization": "Bearer token"]
///   ```
public struct HTTPHeaders {
    
    /// **Stores headers** while ensuring uniqueness.
    ///
    /// The structure maintains **case-insensitive uniqueness** by replacing headers with
    /// the same name **instead of allowing duplicates**.
    private var headers: [HTTPHeader] = []
    
    /// **Creates an empty `HTTPHeaders` instance.**
    ///
    /// - Example:
    ///   ```swift
    ///   let headers = HTTPHeaders()
    ///   ```
    public init() {}
    
    /// **Initializes `HTTPHeaders` from an array**, ensuring no duplicate headers exist.
    ///
    /// Creates an instance from an array of `HTTPHeader`s. Duplicate case-insensitive names are collapsed into the last
    /// name and value encountered.
    ///
    /// - Parameter headers: An array of `HTTPHeader` objects.
    ///
    /// - Note: If multiple headers have the **same case-insensitive name**, only **the last one is kept**.
    public init(_ headers: [HTTPHeader]) {
        headers.forEach { update($0) }
    }
    
    /// **Initializes `HTTPHeaders` from a `[String: String]` dictionary**.
    ///
    /// Creates an instance from a `[String: String]`. Duplicate case-insensitive names are collapsed into the last name
    /// and value encountered.
    ///
    /// - Parameter dictionary: A dictionary where **keys are header names** and **values are header values**.
    ///
    /// - Note: If multiple headers have the **same case-insensitive name**, only **the last one is kept**.
    public init(_ dictionary: [String: String]) {
        dictionary.forEach { update(HTTPHeader(name: $0.key, value: $0.value)) }
    }

    /// Case-insensitively updates or appends an `HTTPHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HTTPHeader` name.
    ///   - value: The `HTTPHeader` value.
    public mutating func add(name: String, value: String) {
        update(HTTPHeader(name: name, value: value))
    }

    /// Case-insensitively updates or appends the provided `HTTPHeader` into the instance.
    ///
    /// - Parameter header: The `HTTPHeader` to update or append.
    public mutating func add(_ header: HTTPHeader) {
        update(header)
    }
    
    /// **Adds or updates an HTTP header** with the given `name` and `value`.
    ///
    /// Case-insensitively updates or appends an `HTTPHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The **header name** (e.g., `"Content-Type"`).
    ///   - value: The **header value** (e.g., `"application/json"`).
    ///
    /// - Example:
    ///   ```swift
    ///   headers.add(name: "Authorization", value: "Bearer token")
    ///   ```
    public mutating func update(name: String, value: String) {
        update(HTTPHeader(name: name, value: value))
    }
    
    /// **Adds or updates an HTTP header** from an `HTTPHeader` instance.
    ///
    /// Case-insensitively updates or appends the provided `HTTPHeader` into the instance.
    ///
    /// - Parameter header: The `HTTPHeader` instance to add or update.
    ///
    /// - Example:
    ///   ```swift
    ///   headers.add(HTTPHeader(name: "User-Agent", value: "MyApp/1.0"))
    ///   ```
    public mutating func update(_ header: HTTPHeader) {
        /// Find the index of the header (case-insensitive).
        guard let index = headers.index(of: header.name) else {
            /// Append new header if it does not exist.
            headers.append(header)
            return
        }
        /// Replace existing header with the new value.
        headers.replaceSubrange(index...index, with: [header])
    }
    

    /// **Removes an HTTP header** by its `name` (case-insensitive).
    ///
    /// Case-insensitively removes an `HTTPHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The **header name** to remove (e.g., `"Authorization"`).
    ///
    /// - Example:
    ///   ```swift
    ///   headers.remove(name: "User-Agent")
    ///   ```
    public mutating func remove(name: String) {
        /// Find the index of the header (case-insensitive).
        guard let index = headers.index(of: name) else {
            return
        }
        /// Remove the header at the found index.
        headers.remove(at: index)
    }
    
    /// **Returns all headers as a `[String: String]` dictionary.**
    ///
    /// The dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the instance.
    ///
    /// - Note: This method **does not preserve the original order** of the headers.
    ///
    /// - Example:
    ///   ```swift
    ///   let dict = headers.dictionary
    ///   print(dict) // ["Content-Type": "application/json", "Authorization": "Bearer token"]
    ///   ```
    public var dictionary: [String: String] {
        let namesAndValues = headers.map { ($0.name, $0.value) }
        return Dictionary(namesAndValues, uniquingKeysWith: { _, last in last })
    }
    
}
