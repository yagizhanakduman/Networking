//
//  StreamTaskHandler.swift
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

/// Defines supported decoding strategies for handling streaming HTTP responses.
///
/// This enum is used to determine how incoming data chunks from a streaming task should be parsed.
///
/// - `plainJSON`: Expects the entire stream to contain a complete JSON object. Once all data is received,
///                it is decoded as a single `Decodable` entity. Useful for traditional JSON API responses.
///
/// - `eventStream`: Expects the stream to be formatted as `text/event-stream`, where each line is prefixed
///                  with `"data: "` and terminated with `\n`. Each `data:` line represents an independent
///                  JSON object that is decoded and emitted incrementally.
///
/// - Example:
///   ```swift
///   let strategy: StreamDecodingStrategy = .eventStream
///   ```
public enum StreamDecodingStrategy {
    case plainJSON /// Normal JSON response
    case eventStream /// text/event-stream → data: {...} + [DONE]
}

/// A type-erased protocol for stream-based data handlers used in decoding network streams.
///
/// Conformers of this protocol are responsible for receiving incoming streamed `Data` chunks,
/// processing them (e.g., decoding), and notifying about the final result upon completion.
///
/// This is typically used to abstract streaming logic regardless of the underlying decoded type.
///
/// - Note:
///   - You should use a concrete type like `StreamTaskHandler<T>` to handle decoding for a specific `Decodable` type.
///   - This protocol enables the use of heterogeneous stream handlers in collections or routing logic.
protocol AnyStreamHandler {
    func append(_ data: Data)
    func finish(request: URLRequest?, response: URLResponse?, error: Error?)
}

/// A generic handler for decoding streamed HTTP response data, supporting both JSON and `text/event-stream` formats.
///
/// This class accumulates incoming data chunks from a `URLSession` streaming task, decodes them incrementally,
/// and emits each decoded object through the provided `onChunk` closure. It also reports final completion through
/// the `completion` closure when the stream ends or encounters an error.
///
/// The handler supports two decoding strategies:
/// - `.plainJSON`: A complete JSON payload per response (replaces internal buffer each time).
/// - `.eventStream`: Server-Sent Events (SSE) formatted as `text/event-stream` using `data:` prefixes and `[DONE]` terminator.
///
/// - Note:
///   - This class is typically used with long-lived streaming APIs (e.g., chat, telemetry, real-time data).
///   - Buffer management is internal and reset after each successful decode attempt.
///   - Thread-safe via internal `DispatchQueue` delivery.
///
/// - Parameters:
///   - T: The expected `Decodable` type emitted from the stream (e.g., `MessageChunk`, `TelemetryPayload`).
final class StreamTaskHandler<T: Decodable>: AnyStreamHandler {
    
    /// The JSON decoder used for decoding each incoming chunk
    private let decoder: JSONDecoder
    
    /// Determines how incoming stream data should be interpreted (`plainJSON` vs `eventStream`)
    private let decodingStrategy: StreamDecodingStrategy
    
    /// The queue on which decoded chunks and the completion handler are dispatched
    private let queue: DispatchQueue
    
    /// Closure invoked with each successfully decoded response chunk
    private let onChunk: (NetworkingResponse<T>) -> Void
    
    /// Closure invoked at the end of the stream, reporting success or failure
    private let completion: (NetworkingResponse<Void>) -> Void
    
    /// An optional cache policy associated with the original request (not used internally)
    private let cachePolicy: CachePolicy?
    
    /// The original `URLRequest` associated with the streaming task
    private let request: URLRequest
    
    /// Internal buffer that accumulates incoming raw data for decoding
    private var buffer = Data()
    
    /// Initializes a new `StreamTaskHandler`.
    ///
    /// - Parameters:
    ///   - decoder: The `JSONDecoder` used to parse streamed data.
    ///   - decodingStrategy: The strategy used to interpret incoming data (`plainJSON` or `eventStream`).
    ///   - queue: The dispatch queue for delivering `onChunk` and `completion` events (default: `.main`).
    ///   - onChunk: A closure called for each successfully decoded `T` object.
    ///   - completion: A closure called when the stream completes or fails.
    ///   - cachePolicy: An optional cache policy used for metadata or analytics.
    ///   - request: The original URL request that initiated the stream.
    init(decoder: JSONDecoder = JSONDecoder(), decodingStrategy: StreamDecodingStrategy, queue: DispatchQueue = .main, onChunk: @escaping (NetworkingResponse<T>) -> Void, completion: @escaping (NetworkingResponse<Void>) -> Void, cachePolicy: CachePolicy?, request: URLRequest) {
        self.decoder = decoder
        self.decodingStrategy = decodingStrategy
        self.queue = queue
        self.onChunk = onChunk
        self.completion = completion
        self.cachePolicy = cachePolicy
        self.request = request
    }
    
    /// Appends new data from the stream and attempts to decode it.
    ///
    /// - Parameter data: A chunk of `Data` received from the URL session.
    ///
    /// - Note:
    ///   - For `.plainJSON`, the entire buffer is decoded and then cleared.
    ///   - For `.eventStream`, the string is split by `\n`, filtered by `data:` prefix, and decoded line-by-line.
    func append(_ data: Data) {
        buffer.append(data)
        switch decodingStrategy {
        case .plainJSON:
            decodePlainJSON()
        case .eventStream:
            decodeEventStream()
        }
    }
    
    /// Attempts to decode a single JSON object from the current buffer using `T.self`.
    ///
    /// - Note:
    ///   - Emits a success or decoding error via `onChunk`.
    ///   - Clears the buffer after processing.
    private func decodePlainJSON() {
        do {
            let chunk = try decoder.decode(T.self, from: buffer)
            queue.async {
                self.onChunk(NetworkingResponse(
                    request: self.request,
                    response: nil,
                    data: self.buffer,
                    result: .success(chunk)
                ))
            }
        } catch {
            queue.async {
                self.onChunk(NetworkingResponse(
                    request: self.request,
                    response: nil,
                    data: self.buffer,
                    result: .failure(.decodingError(error))
                ))
            }
        }
        buffer.removeAll()
    }
    
    /// Decodes SSE-formatted `text/event-stream` chunks from the current buffer.
    ///
    /// - Note:
    ///   - Filters lines starting with `data: `.
    ///   - Ignores lines matching `[DONE]`.
    ///   - Each `data:` line is treated as an independent JSON payload.
    private func decodeEventStream() {
        guard let rawString = String(data: buffer, encoding: .utf8) else {
            queue.async {
                self.onChunk(NetworkingResponse(
                    request: self.request,
                    response: nil,
                    data: self.buffer,
                    result: .failure(.decodingError(NSError(domain: "Invalid UTF-8", code: 0)))
                ))
            }
            return
        }
        
        let lines = rawString
            .components(separatedBy: .newlines)
            .filter { $0.hasPrefix("data: ") }
            .map { $0.replacingOccurrences(of: "data: ", with: "") }
        
        for line in lines {
            if line == "[DONE]" {
                continue
            }
            
            guard let lineData = line.data(using: .utf8) else { continue }
            
            do {
                let chunk = try decoder.decode(T.self, from: lineData)
                queue.async {
                    self.onChunk(NetworkingResponse(
                        request: self.request,
                        response: nil,
                        data: lineData,
                        result: .success(chunk)
                    ))
                }
            } catch {
                queue.async {
                    self.onChunk(NetworkingResponse(
                        request: self.request,
                        response: nil,
                        data: lineData,
                        result: .failure(.decodingError(error))
                    ))
                }
            }
        }
        
        buffer.removeAll()
    }
    
    /// Finalizes the stream and notifies the caller about success or error.
    ///
    /// - Parameters:
    ///   - request: The original `URLRequest` (if available).
    ///   - response: The received `URLResponse` from the stream.
    ///   - error: An optional `Error` if the stream ended due to failure.
    ///
    /// - Note:
    ///   - The `completion` closure is always called, delivering a `NetworkingResponse<Void>`.
    ///   - If an error occurred, it is wrapped in `.failure(.unknown(error))`.
    func finish(request: URLRequest?, response: URLResponse?, error: Error?) {
        let result: Result<Void, NetworkError> = {
            if let err = error {
                return .failure(.unknown(err))
            } else {
                return .success(())
            }
        }()
        queue.async {
            self.completion(NetworkingResponse(
                request: request,
                response: response,
                data: nil,
                result: result
            ))
        }
    }
    
}
