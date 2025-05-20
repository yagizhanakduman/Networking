//
//  MultipartFormDataBuilder.swift
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

/// A lightweight builder for creating `multipart/form-data` request bodies.
///
/// This class helps construct a well-formatted `multipart/form-data` payload by appending files or raw data parts.
/// It manages boundary generation and formatting, ensuring compatibility with `URLSessionUploadTask`.
///
/// - Usage:
///   - Append files using `append(_:withName:fileName:mimeType:)`.
///   - Append raw `Data` with optional MIME type.
///   - Finalize the form using `finalize()` to obtain the `Data` and boundary string.
///
/// - Thread Safety:
///   - This class is **not thread-safe**. Do not mutate from multiple threads.
public final class MultipartFormDataBuilder {
    
    /// A unique boundary string that separates each part of the multipart body.
    ///
    /// - Format: `"Boundary-<UUID>"`, ensures no conflict with the data content.
    private let boundary: String
    
    /// The internal data buffer holding the multipart body.
    ///
    /// - Note:
    ///   - This buffer is incrementally built as parts are appended.
    private var body = Data()
    
    /// Initializes a new `MultipartFormDataBuilder` with an optional custom boundary.
    ///
    /// - Parameters:
    ///   - boundary: An optional custom boundary string. Defaults to a UUID-based random boundary.
    ///
    /// - Note:
    ///   - Using a unique boundary helps avoid accidental corruption when uploading user-generated content.
    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }
    
    /// Appends the contents of a file located at a given URL.
    ///
    /// This method reads the file's data from disk and appends it to the form as a file part.
    ///
    /// - Parameters:
    ///   - fileURL: The local URL of the file to be appended.
    ///
    ///   - name: The name of the form field.
    ///
    ///   - fileName: Optional override for the filename. Defaults to `fileURL.lastPathComponent`.
    ///
    ///   - mimeType: Optional override for the MIME type.
    ///               - If not provided, a best-effort guess is made based on the file extension.
    ///
    /// - Note:
    ///   - If the file cannot be read, an `assertionFailure` is triggered in debug builds.
    public func append(_ fileURL: URL,
                       withName name: String,
                       fileName: String? = nil,
                       mimeType: String? = nil) {
        do {
            let data = try Data(contentsOf: fileURL)
            append(data,
                   withName: name,
                   fileName: fileName ?? fileURL.lastPathComponent,
                   mimeType: mimeType ?? fileURL.mimeTypeGuess)
        } catch {
            assertionFailure("Multipart append error: \(error)")
        }
    }

    /// Appends raw `Data` to the form body.
    ///
    /// This is useful for uploading dynamically generated content or data already in memory.
    ///
    /// - Parameters:
    ///   - data: The binary `Data` to include in the form.
    ///
    ///   - name: The form field name for this data.
    ///
    ///   - fileName: Optional file name, required if sending as a file part.
    ///
    ///   - mimeType: Optional MIME type (e.g., `"image/png"`, `"application/json"`).
    ///
    /// - Note:
    ///   - Proper formatting of headers (Content-Disposition, Content-Type) is handled internally.
    public func append(_ data: Data,
                       withName name: String,
                       fileName: String? = nil,
                       mimeType: String? = nil) {

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        var disposition = "Content-Disposition: form-data; name=\"\(name)\""
        if let fileName { disposition += "; filename=\"\(fileName)\"" }
        body.append("\(disposition)\r\n".data(using: .utf8)!)

        if let mimeType {
            body.append("Content-Type: \(mimeType)\r\n".data(using: .utf8)!)
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }

    /// Finalizes the form body and returns the complete `Data` and boundary string.
    ///
    /// This method appends the closing boundary required to terminate a multipart form.
    ///
    /// - Returns: A tuple containing:
    ///   - `data`: The finalized `Data` representing the entire form body.
    ///   - `boundary`: The boundary string used to separate parts.
    ///
    /// - Example:
    ///   ```swift
    ///   let (data, boundary) = builder.finalize()
    ///   ```
    public func finalize() -> (data: Data, boundary: String) {
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return (body, boundary)
    }
    
}

/// Mime Type Guessing
///
/// Attempts to determine a basic MIME type based on the file extension.
///
/// This extension provides a heuristic for setting the `Content-Type` header
/// when appending files via `fileURL`.
///
/// - Note:
///   - If the extension is unknown, defaults to `"application/octet-stream"`.
fileprivate extension URL {
    
    var mimeTypeGuess: String {
        switch pathExtension.lowercased() {
        case "png":  return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":  return "image/gif"
        case "pdf":  return "application/pdf"
        default:     return "application/octet-stream"
        }
    }
    
}
