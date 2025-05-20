//
//  VoidPlaceholder.swift
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

// MARK: - VoidPlaceholder

/// **A placeholder type for handling empty API responses in `responseVoid()`.**
///
/// Some API endpoints return **204 No Content** or an empty response body. However, `Decodable`
/// requires a concrete type for decoding, and `Void` **cannot** conform to `Decodable`.
///
/// `VoidPlaceholder` serves as a dummy type used **internally by `responseVoid()`** to allow
/// requests to return `Void` while ensuring proper decoding.
///
/// - **How does this work?**
///   - Instead of attempting to decode an empty response into a `Void` type (which is invalid),
///     we decode it into `VoidPlaceholder`, which does **nothing**.
///   - `responseVoid()` then maps the result to `Void` (`()`), making it behave as expected.
///
/// - **Usage Example with `responseVoid()`:**
///   ```swift
///   networking.request(url: URL(string: "https://api.example.com/logout")!)
///       .responseVoid { result in
///           switch result {
///           case .success:
///               print("Logout successful!") /// ✅ Returns Void as expected
///           case .failure(let error):
///               print("Request failed:", error)
///           }
///       }
///   ```
///
/// - **Thread Safety:**
///   - `VoidPlaceholder` is inherently **thread-safe** since it has no stored properties.
///   - Ensure **UI updates** after API calls are performed on the **main thread**.
///
/// - **Key Benefit:**
///   - Enables `responseVoid()` to **seamlessly return `Void`**, even when the API response is empty.
struct VoidPlaceholder: Decodable & Equatable {
    
    /// **Decodes an empty response body without failing.**
    ///
    /// - Throws: Nothing (this initializer always succeeds).
    /// - Note: This method is **intentionally empty** because the response body is ignored.
    init(from decoder: Decoder) throws {
        /// No fields to decode; simply ignore any response body.
    }
    
}
