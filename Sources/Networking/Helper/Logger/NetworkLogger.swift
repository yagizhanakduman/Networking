//
//  NetworkLogger.swift
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
import os.log

// MARK: - Network Logger Protocol

/// A protocol that defines methods for logging network requests and responses.
///
/// Implementing this protocol allows network activity to be logged in a structured way,
/// making debugging and performance monitoring easier.
public protocol NetworkLoggerProtocol {
    
    /// Logs details of an outgoing network request.
    ///
    /// - Parameter request: The `URLRequest` representing the network request to be logged.
    ///
    /// - Note:
    ///   This method is typically used to capture key information about the request,
    ///   such as the HTTP method, URL, headers, and body.
    ///
    /// - Example:
    ///   ```swift
    ///   networkLogger.log(request: someURLRequest)
    ///   ```
    func log(request: URLRequest)
    
    /// Logs a network request in `cURL` format for debugging.
    ///
    /// - Parameter request: The `URLRequest` representing the network request to be converted to a `cURL` command.
    ///
    /// - Note:
    ///   This method allows developers to reproduce network requests in a terminal using `cURL`,
    ///   making it easier to troubleshoot issues outside of the application.
    ///
    /// - Example:
    ///   ```swift
    ///   networkLogger.cURLLog(request: someURLRequest)
    ///   ```
    func cURLLog(request: URLRequest)
    
    /// Logs details of a network response, including optional response body data and errors.
    ///
    /// - Parameters:
    ///   - responseData: The response body data (if available).
    ///   - response: The `URLResponse` received from the network request.
    ///   - error: An optional `Error` if the request failed.
    ///
    /// - Note:
    ///   This method should be used to capture key details about the response,
    ///   such as HTTP status codes, headers, and response body contents.
    ///
    /// - Example:
    ///   ```swift
    ///   networkLogger.log(responseData: responseData, response: urlResponse, error: networkError)
    ///   ```
    func log(responseData: Data?, response: URLResponse?, error: Error?)
    
    /// Logs a custom message for debugging or informational purposes.
    ///
    /// - Parameters:
    ///   - message: A string message to be logged.
    ///   - level: The severity level of the log (e.g., `.debug`, `.error`).
    ///   - logPrivacy: The privacy level of the log message (`.public`, `.private`, `.sensitive`, `.auto`).
    ///
    /// - Note:
    ///   - Custom log messages allow developers to add additional context to network-related events.
    ///   - Privacy settings help determine how log messages are displayed in system logs.
    ///   - Apple's `OSLog` framework enforces privacy rules at compile-time, meaning that privacy settings
    ///     must be statically defined.
    ///
    /// - Example:
    ///   ```swift
    ///   networkLogger.logMessage(message: "User logged in", level: .info, logPrivacy: .private)
    ///   networkLogger.logMessage(message: "Fetching data from API", level: .debug, logPrivacy: .public)
    ///   ```
    func logMessage(message: String, level: OSLogType, logPrivacy: LogPrivacy)
    
}

// MARK: - Network Logger

/// A concrete implementation of `NetworkLoggerProtocol` for logging network requests and responses.
///
/// This logger captures request details, response details, and errors, allowing for easier debugging.
/// The logging is handled using Apple's `os.log` framework, which is optimized for performance and security.
public class NetworkLogger: NetworkLoggerProtocol {
    /// The system logger instance for network-related logs.
    private let networkLogger = Logger(subsystem: "com.networking.logger", category: "network")
    
    /// Initializes a new `NetworkLogger` instance.
    public init() {}
    
    /// Logs an outgoing network request.
    ///
    /// - Parameter request: The `URLRequest` instance to be logged.
    ///
    /// - Note:
    ///   This method logs:
    ///   - The request URL (public visibility).
    ///   - The HTTP method (GET, POST, etc.).
    ///   - Headers (marked private to protect sensitive data like tokens).
    ///   - The request body (also private to prevent exposure of sensitive user data).
    public func log(request: URLRequest) {
        let timestamp = Date().timeIntervalSince1970
        /// Log Request Start
        networkLogger.info("[\(timestamp)] Request Initiated")
        /// URL
        networkLogger.info("Request URL: \(request.url?.absoluteString ?? "Unknown URL", privacy: .public)")
        /// HTTP Method
        networkLogger.info("Method: \(request.httpMethod ?? "Unknown Method", privacy: .public)")
        /// Headers
        if let headers = request.allHTTPHeaderFields {
            networkLogger.info("Headers: \(headers, privacy: .private)")
        }
        /// Body
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8),
           !bodyString.isEmpty {
            networkLogger.info("Headers: \(bodyString, privacy: .private)")
        }
        /// Log Complete
        networkLogger.info("[\(timestamp)] Request logging completed.")
    }
    
    /// Logs details of a network response, including status codes, response data, and errors.
    ///
    /// - Parameters:
    ///   - responseData: The response body data (if available).
    ///   - response: The `URLResponse` received from the request.
    ///   - error: An optional `Error` if the request failed.
    ///
    /// - Note:
    ///   This method logs:
    ///   - HTTP status codes (e.g., 200 OK, 404 Not Found).
    ///   - Response bodies (marked private).
    ///   - Error descriptions (if the request failed).
    public func log(responseData: Data?, response: URLResponse?, error: Error?) {
        let timestamp = Date().timeIntervalSince1970
        /// Log Response Start
        networkLogger.info("[\(timestamp)] Response Received")
        /// HTTP Status Code
        if let httpResponse = response as? HTTPURLResponse {
            networkLogger.info("Response Status Code: \(httpResponse.statusCode, privacy: .public)")
        }
        /// Error
        if let error = error {
            networkLogger.info("Error: \(error.localizedDescription, privacy: .public)")
        }
        /// Body
        if let data = responseData,
           let dataString = String(data: data, encoding: .utf8),
           !dataString.isEmpty {
            networkLogger.info("Response Body: \(dataString, privacy: .private)")
        }
        /// Log Complete with Error or No Error
        if error == nil {
            networkLogger.debug("[\(timestamp)] Response logging completed (no error).")
        } else {
            networkLogger.debug("[\(timestamp)] Response logging completed with error.")
        }
    }
    
    // MARK: - cURL Network Log
    
    /// Logs a network request in `cURL` format for debugging purposes.
    ///
    /// - Parameter request: The `URLRequest` instance to be logged as a `cURL` command.
    ///
    /// - Note:
    ///   This is particularly useful when debugging API requests by replicating them
    ///   in a command-line environment.
    public func cURLLog(request: URLRequest) {
        let timestamp = Date().timeIntervalSince1970
        /// Log cURL Start
        networkLogger.info("[\(timestamp)] Creating cURL command.")
        if let curlCommand = makeCURLCommand(request: request) {
            networkLogger.info("Request as cURL: \(curlCommand, privacy: .public)")
        }
        /// Log Complete
        networkLogger.info("[\(timestamp)] Request cURL logging completed.")
    }
    
    /// Constructs a `cURL` command representation of a `URLRequest`.
    ///
    /// - Parameter request: The `URLRequest` instance to be converted.
    /// - Returns: A `String` representing the request as a `cURL` command.
    ///
    /// - Note:
    ///   This method generates a `cURL` command that can be copied and executed in a terminal
    ///   to reproduce the request, making debugging easier.
    private func makeCURLCommand(request: URLRequest) -> String? {
        guard let url = request.url else {
            return nil
        }
        var components = ["curl"]
        /// HTTP Method
        if let method = request.httpMethod {
            components.append("-X \(method)")
        }
        /// Headers
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                components.append("-H '\(key): \(value)'")
            }
        }
        /// Body
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8),
           !bodyString.isEmpty {
            let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\\''")
            components.append("-d '\(escapedBody)'")
        }
        components.append("'\(url.absoluteString)'")
        return components.joined(separator: " ")
    }
    
    
    // MARK: - Custom Message Log
    
    /// Logs a custom message with the specified log level and privacy setting.
    ///
    /// - Parameters:
    ///   - message: The message string to be logged.
    ///   - level: The severity level of the log (default: `.debug`).
    ///   - logPrivacy: The privacy level of the log message (default: `.auto`).
    ///
    /// - Note:
    ///   Apple's logging APIs utilize special compiler features to evaluate the privacy level at compile time.
    ///   The `OSLogPrivacy` options must be defined statically (i.e., known at compile time), meaning
    ///   they cannot be dynamically assigned at runtime.
    ///
    /// - Important:
    ///   Due to the compile-time nature of privacy settings, we cannot dynamically wrap OSLog APIs
    ///   without using compiler-internal features. The logging framework requires the privacy setting
    ///   to be explicitly declared per message, preventing dynamic evaluation during runtime.
    ///
    /// - Example:
    ///   ```swift
    ///   logMessage(message: "User logged in", level: .info, logPrivacy: .private)
    ///   logMessage(message: "Fetching data from API", level: .debug, logPrivacy: .public)
    ///   ```
    public func logMessage(message: String, level: OSLogType = .debug, logPrivacy: LogPrivacy = .auto) {
        /// The logging APIs use special compiler features to evaluate the privacy level at compile time
        /// We must use a static (i.e., known at compile time) method or property of ‘OSLogPrivacy’; it can’t be a variable that’s evaluated at run time.
        /// The implication is that we can’t create your own wrapper for these APIs without using compiler-internal features.
        let timestamp = Date().timeIntervalSince1970
        switch logPrivacy {
        case .public:
            /// Logs the message with `.public` privacy, meaning it will be visible in system logs.
            networkLogger.log(level: level, "[\(timestamp)] \(message, privacy: .public)")
        case .private:
            /// Logs the message with `.private` privacy, meaning it will be redacted in system logs.
            networkLogger.log(level: level, "[\(timestamp)] \(message, privacy: .private)")
        case .sensitive:
            /// Logs the message with `.sensitive` privacy, which is similar to `.private` but used for highly sensitive data.
            networkLogger.log(level: level, "[\(timestamp)] \(message, privacy: .sensitive)")
        case .auto:
            /// Logs the message with `.auto` privacy, allowing the system to determine the appropriate privacy level. Default is `.private`
            networkLogger.log(level: level, "[\(timestamp)] \(message, privacy: .auto)")
        }
    }
    
}
