//
//  NetworkError.swift
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

// MARK: - Networking Error

/// Represents possible errors that can occur during network operations.
///
/// `NetworkError` standardizes network-related failures, making it easier to diagnose and handle issues.
/// This enum covers various failure scenarios, including request failures, decoding errors, network reachability,
/// and server-side errors.
///
/// - Cases:
///   - `invalidURL`: The provided URL is invalid or malformed.
///   - `invalidRequest`: The request could not be created due to missing parameters or an incorrect format.
///   - `requestFailed(statusCode:data:)`: The request received an **unsuccessful HTTP status code**.
///       - `statusCode`: The HTTP status code returned by the server.
///       - `data`: Optional response data that may contain an error message from the server.
///   - `decodingError(Error)`: The response data could not be decoded into the expected format.
///   - `unknown(Error?)`: An **unhandled error** occurred during the network request.
///   - `noData`: The request completed successfully but returned **empty data**.
///   - `downloadFailed(NSError?)`: The download operation failed, optionally containing an underlying `NSError`.
///   - `uploadFailed(NSError?)`: The upload operation failed, optionally containing an underlying `NSError`.
///   - `noInternetConnection`: The device is offline and **no active internet connection is available**.
///   - `timeout`: The request took too long to complete due to **server unresponsiveness or slow connection**.
///   - `networkUnavailable`: The network is temporarily unreachable, possibly due to **weak signal or server downtime**.
///
/// - Features:
///   - **Standardized error handling**: Provides a single enum for all network-related errors.
///   - **Debugging support**: Includes detailed cases to help pinpoint failures.
///   - **Response handling**: Captures failed request status codes and response data.
///
/// - Use Cases:
///   - **Handling API failures gracefully**: Retrying requests based on error type.
///   - **User feedback**: Displaying appropriate error messages based on the failure type.
///   - **Debugging network failures**: Logging detailed errors for later analysis.
///
/// - Example Usage:
///   ```swift
///   func handleError(_ error: NetworkError) {
///       switch error {
///       case .invalidURL:
///           print("❌ Invalid URL provided. Please check your request URL.")
///       case .invalidRequest:
///           print("⚠️ The request could not be created due to missing or malformed data.")
///       case .requestFailed(let statusCode, let data):
///           if let responseData = data, let errorMessage = String(data: responseData, encoding: .utf8) {
///               print("🚨 Request failed with status code \(statusCode): \(errorMessage)")
///           } else {
///               print("🚨 Request failed with status code \(statusCode).")
///           }
///       case .decodingError(let decodingError):
///           print("📉 Failed to decode response: \(decodingError.localizedDescription)")
///       case .noInternetConnection:
///           print("📶 No internet connection. Please check your network settings.")
///       case .timeout:
///           print("⏳ The request timed out. The server may be unresponsive.")
///       case .networkUnavailable:
///           print("📡 Network unavailable. Try again when the connection is more stable.")
///       case .unknown(let error):
///           print("❓ An unknown error occurred: \(error?.localizedDescription ?? "No details available")")
///       default:
///           print("⚠️ A network error occurred.")
///       }
///   }
///   ```
public enum NetworkError: Error {
    
    /// The provided URL is invalid or incorrectly formatted.
    case invalidURL
    
    /// The request could not be constructed due to missing parameters or incorrect formatting.
    case invalidRequest
    
    /// The server responded with a non-success HTTP status code.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - data: Optional response data, which may contain an error message.
    ///
    /// - Example:
    ///   ```swift
    ///   case .requestFailed(statusCode: 400, data: responseData)
    ///   ```
    case requestFailed(statusCode: Int, data: Data?)
    
    /// The response data could not be decoded into the expected format.
    ///
    /// - Parameter error: The underlying decoding error.
    ///
    /// - Example:
    ///   ```swift
    ///   case .decodingError(error)
    ///   ```
    case decodingError(Error)
    
    /// An unexpected or unclassified network error occurred.
    ///
    /// - Parameter error: The optional underlying error.
    case unknown(Error?)
    
    /// The request completed successfully, but the response contained no data.
    case noData
    
    /// The file download operation failed.
    ///
    /// - Parameter error: The optional underlying error providing more details.
    case downloadFailed(Error?)
    
    /// The file upload operation failed.
    ///
    /// - Parameter error: The optional underlying error providing more details.
    case uploadFailed(Error?)
    
    /// The device has no active internet connection.
    ///
    /// - Note:
    ///   - This error is triggered when the **network reachability check** fails.
    ///   - Can be used to notify users when they are **offline**.
    case noInternetConnection
    
    /// The network request **timed out**, likely due to **server unresponsiveness or slow connection**.
    ///
    /// - Use Case:
    ///   - When a request takes longer than expected due to **network congestion** or **slow response time**.
    case timeout
    
    /// The network is temporarily **unavailable**, possibly due to **weak signal or server downtime**.
    ///
    /// - Use Case:
    ///   - Useful when network reachability **fluctuates** (e.g., weak Wi-Fi or mobile network signal).
    case networkUnavailable
}

// MARK: - Equatable
extension NetworkError: Equatable {
    
    /// Provides equality comparison for `NetworkError`.
    ///
    /// - Note:
    ///   - **Associated error objects (e.g., in `.decodingError`, `.unknown`, `.downloadFailed`) are not deeply compared.**
    ///   - This is intentional, because:
    ///     - `Error` doesn't conform to `Equatable`.
    ///     - Comparing errors by pointer equality or description is **unreliable**.
    ///     - Only the **case type and basic parameters (status codes, data, etc.)** are compared.
    ///   - **Use Cases:**
    ///     - Helpful when matching error types in unit tests or handling specific cases.
    ///     - Not intended for detailed equality on underlying `Error` values.
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidRequest, .invalidRequest):
            return true
        case (.requestFailed(let lhsStatus, let lhsData), .requestFailed(let rhsStatus, let rhsData)):
            return lhsStatus == rhsStatus && lhsData == rhsData
        case (.decodingError, .decodingError):
            return true
        case (.unknown, .unknown):
            return true
        case (.noData, .noData):
            return true
        case (.downloadFailed, .downloadFailed):
            return true
        case (.uploadFailed, .uploadFailed):
            return true
        case (.noInternetConnection, .noInternetConnection):
            return true
        case (.timeout, .timeout):
            return true
        case (.networkUnavailable, .networkUnavailable):
            return true
        default:
            return false
        }
    }
    
}
