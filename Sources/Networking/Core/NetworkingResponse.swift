//
//  NetworkingResponse.swift
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

/// A type that encapsulates the full response from a networking request,
/// including metadata, raw data, and the result of decoding the response.
///
/// `NetworkingResponse` provides convenient access to the original request,
/// server response, raw response data, and the result of attempting to decode
/// the response into a specified type.
///
/// This generic type is used throughout the networking layer to standardize
/// how responses are passed and interpreted.
///
/// - Parameters:
///   - Value: The expected type of the decoded response body. This is usually a model
///            conforming to `Decodable`.
///
/// Example usage:
/// ```swift
/// let response: NetworkingResponse<User> = ...
/// if response.isSuccess {
///     print("Received user:", response.value)
/// } else if let error = response.error {
///     print("Request failed with error:", error)
/// }
/// ```
///
/// - Thread Safety:
///   `NetworkingResponse` is a value type (`struct`) and is immutable after creation,
///   so it is inherently thread-safe as long as `Value` is thread-safe.
///
/// - Note:
///   This type does not perform any network operations on its own. It is a passive
///   container for data returned by a network call, typically created by a `Request`
///   or `Networking` layer in your architecture.
///
public struct NetworkingResponse<Value> {
    
    /// The original `URLRequest` that was sent to the server.
    ///
    /// This may be useful for debugging, logging, or correlating responses
    /// to their respective requests.
    public let request: URLRequest?
    
    /// The `URLResponse` returned by the server.
    ///
    /// In most cases, this will be an instance of `HTTPURLResponse`, but
    /// may also be another subtype depending on the transport protocol.
    public let response: URLResponse?
    
    /// The raw response body returned by the server, if any.
    ///
    /// This data is typically used to decode into a typed model, or for
    /// debugging and fallback parsing when decoding fails.
    public let data: Data?
    
    /// The result of attempting to decode the response into a `Value`.
    ///
    /// This contains either the successfully decoded value or a `NetworkError`
    /// describing what went wrong during the request or decoding process.
    public let result: Result<Value, NetworkError>
    
    /// A Boolean value indicating whether the request was successful.
    ///
    /// This will be `true` if the `result` contains a `.success` value,
    /// and `false` otherwise.
    public var isSuccess: Bool {
        if case .success = result { return true }
        return false
    }
    
    /// The decoded response value, if the request and decoding succeeded.
    ///
    /// This provides convenient access to the typed `Value` without needing
    /// to manually extract it from the `result`.
    public var value: Value? {
        if case let .success(value) = result {
            return value
        }
        return nil
    }
    
    /// The error that occurred during the request or decoding, if any.
    ///
    /// Returns the associated `NetworkError` if the result was `.failure`.
    public var error: NetworkError? {
        if case let .failure(err) = result {
            return err
        }
        return nil
    }

    /// A human-readable description of the networking response,
    /// useful for debugging and logging.
    public var description: String {
        var components: [String] = []
        components.append("Request: \(request?.url?.absoluteString ?? "nil")")
        components.append("Response: \(response.debugDescription)")
        components.append("Data: \(data.map { "\($0.count) bytes" } ?? "nil")")
        components.append("Result: \(result)")
        return components.joined(separator: "\n")
    }
    
}
