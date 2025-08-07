//
//  Networking+Stream.swift
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

// MARK: - Stream
public extension Networking {
    
    /// Initiates a streaming network request using a URL string and decodes incoming chunks into the specified `Decodable` type.
    ///
    /// This method sets up a `URLSessionDataTask` that streams data from the server. Incoming data is buffered and decoded incrementally
    /// based on the provided `StreamDecodingStrategy` (e.g., `.plainJSON`, `.eventStream`). Each decoded chunk is passed to the `onChunk` closure,
    /// and the final completion callback is called when the stream ends or encounters an error.
    ///
    /// - Parameters:
    ///   - url: The target URL as a `String`.
    ///   - method: The HTTP method to use (default: `.get`).
    ///   - queryParameters: Optional query parameters to append to the URL.
    ///   - bodyParameters: Optional body parameters to include in the request.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - type: The `Decodable` type into which each chunk of data should be decoded.
    ///   - retryCount: The number of times to retry the request on failure (default: `0`).
    ///   - cachePolicy: Optional cache behavior to apply to the request.
    ///   - queue: The dispatch queue on which both `onChunk` and `completion` closures will be called (default: `.main`).
    ///   - decodingStrategy: Strategy for parsing streamed data (`.plainJSON` or `.eventStream`).
    ///   - onChunk: A closure called with every successfully decoded chunk of data (`NetworkingResponse<T>`).
    ///   - completion: A closure called when the stream finishes or fails, returning a `NetworkingResponse<Void>`.
    ///
    /// - Returns: The created `URLSessionDataTask` if successful, otherwise `nil`.
    ///
    /// - Note:
    ///   - Use `.plainJSON` when the server sends valid JSON in discrete packets.
    ///   - Use `.eventStream` for `text/event-stream` (SSE) formats with `data:` lines and `[DONE]` terminators.
    ///   - This method forwards the request to the internal `request.stream(...)` handler.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   networking.stream(url: "https://api.example.com/stream", of: ChatResponse.self, decodingStrategy: .eventStream, onChunk: { chunk in
    ///       print("Received chunk:", chunk)
    ///   }, completion: { final in
    ///       print("Stream finished:", final)
    ///   })
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Both the `onChunk` and `completion` closures are dispatched on the provided `queue`.
    @discardableResult
    func stream<T: Decodable>(url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, of type: T.Type, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, decodingStrategy: StreamDecodingStrategy = .plainJSON, onChunk: @escaping (NetworkingResponse<T>) -> Void, completion: @escaping (NetworkingResponse<Void>) -> Void) -> URLSessionDataTask? {
        let requestConfig = RequestConfig(url: url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, headers: headers)
        return request.stream(requestConfig, of: type, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decodingStrategy: decodingStrategy, onChunk: onChunk, completion: completion)
    }
    
    /// Initiates a streaming request using a predefined `RequestConfig`, decoding streamed data into the specified `Decodable` type.
    ///
    /// This overload accepts a full `RequestConfig` instead of a raw URL string, allowing greater flexibility and reuse of request parameters.
    /// The response is streamed and decoded chunk-by-chunk using the specified `StreamDecodingStrategy`.
    ///
    /// - Parameters:
    ///   - config: The `RequestConfig` object containing URL, method, parameters, and headers.
    ///   - type: The `Decodable` type into which each streamed chunk should be decoded.
    ///   - retryCount: The number of retry attempts to perform on failure (default: `0`).
    ///   - cachePolicy: Optional caching behavior to apply.
    ///   - queue: The dispatch queue on which the `onChunk` and `completion` closures will be executed (default: `.main`).
    ///   - decodingStrategy: The strategy to decode streamed content (e.g., `.plainJSON`, `.eventStream`).
    ///   - onChunk: Closure invoked for each successfully decoded data chunk (`NetworkingResponse<T>`).
    ///   - completion: Closure invoked when the stream ends or fails, returning a `NetworkingResponse<Void>`.
    ///
    /// - Returns: A `URLSessionDataTask` if the stream was successfully initiated, otherwise `nil`.
    ///
    /// - Note:
    ///   - This overload is ideal when request configuration is constructed outside the call site.
    ///   - Stream decoding strategy determines how the incoming byte stream is parsed and chunked.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let config = RequestConfig(url: "https://api.example.com/stream", method: .get)
    ///   networking.stream(config, of: Event.self, decodingStrategy: .eventStream, onChunk: { response in
    ///       print("Streamed data:", response)
    ///   }, completion: { finalResponse in
    ///       print("Streaming complete.")
    ///   })
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Callbacks are executed on the specified queue.
    @discardableResult
    func stream<T: Decodable>(_ config: RequestConfig, of type: T.Type, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, decodingStrategy: StreamDecodingStrategy = .plainJSON, onChunk: @escaping (NetworkingResponse<T>) -> Void, completion: @escaping (NetworkingResponse<Void>) -> Void) -> URLSessionDataTask? {
        return request.stream(config, of: type, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decodingStrategy: decodingStrategy, onChunk: onChunk, completion: completion)
    }
    
}
