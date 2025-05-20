//
//  UploadTaskHandler.swift
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

// MARK: - Type-erased upload task wrapper

/// A protocol defining a type-erased interface for handling upload task data and finalization.
///
/// This is used to abstract the upload result handling and progress reporting
/// for various `Decodable` types without exposing the generic `Value` type.
///
/// - Purpose:
///   - Enable heterogeneous storage of upload tasks in a dictionary or array.
///   - Allow task buffering, progress tracking, and decoding in a unified manner.
protocol AnyUploadTaskHandler {
    
    /// A closure that reports real-time upload progress as a `Double` between `0.0` and `1.0`.
    var progressHandler: ((Double) -> Void)? { get }
    
    /// Appends a received chunk of data to the internal buffer.
    ///
    /// - Parameter chunk: A `Data` object representing the latest response chunk.
    func append(_ chunk: Data)
    
    /// Finalizes the upload task by decoding or reporting an error.
    ///
    /// - Parameters:
    ///   - request: The original `URLRequest` that initiated the upload.
    ///   - response: The `URLResponse` received from the server.
    ///   - error: A `NetworkError`, if any occurred during the upload.
    func finish(request: URLRequest?,
                response: URLResponse?,
                error: NetworkError?)
}

/// A concrete, generic upload handler that buffers data and decodes the final response.
///
/// This class implements `AnyUploadTaskHandler` and is responsible for:
/// 1. Accumulating streamed data from the upload task.
/// 2. Decoding the buffered data into a concrete `Value` type.
/// 3. Executing the completion handler with a typed `NetworkingResponse<Value>`.
///
/// - Type Parameter:
///   - `Value`: The expected `Decodable` type returned from the server upon successful upload.
final class UploadTaskHandler<Value: Decodable>: AnyUploadTaskHandler {
    
    /// A closure reporting upload progress as a `Double` between `0.0` and `1.0`.
    let progressHandler: ((Double) -> Void)?
    
    /// The completion handler that delivers the final upload result.
    private let completion: (NetworkingResponse<Value>) -> Void
    
    /// An internal buffer used to accumulate streamed response data.
    private var buffer = Data()
    
    /// The JSON decoder used to decode the response data into `Value`.
    private let decoder: JSONDecoder
    
    /// Initializes a new upload task handler with the given progress and completion closures.
    ///
    /// - Parameters:
    ///   - progress: An optional closure reporting upload progress.
    ///
    ///   - decoder: The JSON decoder used for decoding the response body.
    ///              - Defaults to a standard `JSONDecoder()` instance.
    ///
    ///   - completion: A closure that is called once the upload completes,
    ///                 with either the decoded response or an error.
    init(progress: ((Double) -> Void)? = nil, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<Value>) -> Void) {
        self.progressHandler = progress
        self.decoder = decoder
        self.completion = completion
    }
    
    /// Appends a chunk of response `Data` to the internal buffer.
    ///
    /// This is called repeatedly as data arrives during an upload session.
    ///
    /// - Parameter chunk: The latest `Data` block received from the server.
    func append(_ chunk: Data) {
        buffer.append(chunk)
    }
    
    /// Finalizes the upload task by decoding the response or reporting an error.
    ///
    /// This method constructs a `NetworkingResponse` with the decoded result or an error,
    /// and invokes the completion handler.
    ///
    /// - Parameters:
    ///   - request: The original `URLRequest` sent to the server.
    ///
    ///   - response: The `URLResponse` received from the server.
    ///
    ///   - error: A `NetworkError`, if any occurred during upload.
    func finish(request: URLRequest?, response: URLResponse?, error: NetworkError?) {
        if let wrappedError = error {
            completion(.init(request: request,
                             response: response,
                             data: buffer.isEmpty ? nil : buffer,
                             result: .failure(wrappedError)))
            return
        }
        do {
            let decoded = try decoder.decode(Value.self, from: buffer)
            completion(.init(request: request,
                             response: response,
                             data: buffer,
                             result: .success(decoded)))
        } catch {
            completion(.init(request: request,
                             response: response,
                             data: buffer,
                             result: .failure(.decodingError(error))))
        }
    }
    
}
