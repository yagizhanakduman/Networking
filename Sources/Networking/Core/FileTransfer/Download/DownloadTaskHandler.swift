//
//  DownloadTaskHandler.swift
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

/// Type-erased interface for download task tracking.
///
/// `AnyDownloadTaskHandler` provides a common abstraction for handling download-related progress
/// and completion logic without exposing the generic result type. This is essential for storing
/// multiple task handlers in a dictionary with heterogeneous response types.
protocol AnyDownloadTaskHandler {
    
    /// An optional closure that reports download progress as a value between `0.0` and `1.0`.
    ///
    /// - Useful for displaying download indicators in the UI.
    var progressHandler: ((Double) -> Void)? { get }
    
    /// The optional destination file URL where the downloaded file will be saved.
    ///
    /// - If `nil`, the system stores the file in a temporary location.
    var destinationURL: URL? { get }
    
    /// Called when the download finishes, either successfully or with an error.
    ///
    /// - Parameters:
    ///   - location: The local file URL where the downloaded file was stored (if successful).
    ///   - error: The error that occurred during the download, if any.
    func finish(with location: URL?, error: Error?)
}

/// A generic handler for download tasks that decodes the result into a specific type `Value`.
///
/// `DownloadTaskHandler` is responsible for handling download progress and completion logic for a specific task,
/// including type-safe result delivery through the `NetworkingResponse<Value>` wrapper.
///
/// - Note:
///   - `Value` must conform to expected types like `URL` or custom types that the system understands.
///   - This class is typically managed internally by the downloader infrastructure.
final class DownloadTaskHandler<Value>: AnyDownloadTaskHandler {
    
    /// An optional closure that reports download progress as a `Double` in the range `0.0...1.0`.
    ///
    /// - Called periodically during the download task.
    let progressHandler: ((Double) -> Void)?
    
    /// A closure that delivers the final result to the caller, wrapped in `NetworkingResponse<Value>`.
    private let completion: (NetworkingResponse<Value>) -> Void
    
    /// The desired file destination URL, or `nil` if a temporary location is used.
    let destinationURL: URL?
    
    /// Initializes a new `DownloadTaskHandler` with optional progress and a required completion handler.
    ///
    /// - Parameters:
    ///
    ///   - destinationURL: The optional file destination where the downloaded file should be saved.
    ///
    ///   - progress: A closure to receive progress updates during the download.
    ///
    ///   - completion: A closure that delivers the final `NetworkingResponse<Value>` when the download finishes.
    init(destinationURL: URL?, progress: ((Double) -> Void)? = nil, completion: @escaping (NetworkingResponse<Value>) -> Void) {
        self.destinationURL = destinationURL
        self.progressHandler = progress
        self.completion = completion
    }
    
    /// Called when the download operation completes, either successfully or with an error.
    ///
    /// - Parameters:
    ///
    ///   - location: The system-provided file URL where the downloaded file is temporarily saved.
    ///
    ///   - error: The error that occurred during the download, or `nil` if successful.
    ///
    /// - Behavior:
    ///   - If `error` is present, wraps it in `.failure(.downloadFailed(...))`.
    ///   - If `location` is present and castable to `Value`, wraps it in `.success(...)`.
    ///   - If the result type is unexpected, returns `.failure(.unknown(nil))`.
    func finish(with location: URL?, error: Error?) {
        if let wrappedError = error {
            let networkingResponse: NetworkingResponse<Value> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.downloadFailed(wrappedError as NSError)))
            completion(networkingResponse)
        } else if let finalURL = location {
            if let value = finalURL as? Value {
                let networkingResponse: NetworkingResponse<Value> = NetworkingResponse(request: nil, response: nil, data: nil, result: .success(value))
                completion(networkingResponse)
            } else {
                let networkingResponse: NetworkingResponse<Value> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.unknown(nil)))
                completion(networkingResponse)
            }
        } else {
            let networkingResponse: NetworkingResponse<Value> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.unknown(nil)))
            completion(networkingResponse)
        }
    }
    
}
