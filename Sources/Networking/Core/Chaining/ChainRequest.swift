//
//  ChainRequest.swift
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

// MARK: - ChainRequest

/// A class for chaining network requests in a structured way.
///
/// `ChainRequest` allows making network requests using either:
///  - A **URL-based** approach where request parameters are passed directly.
///  - A **RequestConfig-based** approach where a `RequestConfig` object is used.
///
/// This abstraction ensures flexibility in structuring API requests while maintaining
/// clear separation between different request initialization methods.
///
/// - Features:
///   - Supports **chained request execution**.
///   - Works with both **URL-based and `RequestConfig`-based initialization**.
///   - Ensures **type-safe decoding** with `Decodable`.
///   - Supports **retries and caching policies**.
///   - Provides **void response handling** for `204 No Content` requests.
///
/// - Note:
///   - This class simplifies handling multiple request types while ensuring clear separation of concerns.
///   - It integrates seamlessly with the `Networking` class for making API calls.
///   - If **caching is enabled**, responses are stored and retrieved based on the provided `CachePolicy`.
///   - Ensure **proper error handling** in the completion closure to manage network failures gracefully.
///
/// - Thread Safety:
///   - `ChainRequest` is **not inherently thread-safe**.
///   - Ensure that the `completion` closure is executed on the **main thread** when updating UI components.
///   - `Networking` calls run on background threads but should switch to the **main thread** inside `completion`
///     when interacting with UI elements.
///
/// - Example Usage:
///   ```swift
///   let networking = Networking()
///
///   /// URL-based usage
///   networking.request(url: URL(string: "https://api.example.com/data")!)
///       .responseDecodable(of: MyModel.self) { result in
///           DispatchQueue.main.async {
///               switch result {
///               case .success(let model):
///                   print("Received data:", model)
///               case .failure(let error):
///                   print("Request failed:", error)
///               }
///           }
///       }
///
///   /// RequestConfig-based usage
///   let config = RequestConfig(url: URL(string: "https://api.example.com/user")!)
///   networking.request(config)
///       .responseDecodable(of: User.self) { result in
///           DispatchQueue.main.async {
///               switch result {
///               case .success(let user):
///                   print("User data:", user)
///               case .failure(let error):
///                   print("Failed to fetch user:", error)
///               }
///           }
///       }
///   ```
public final class ChainRequest {
    
    /// The `Networking` instance responsible for executing requests.
    private let networking: Networking
    
    // MARK: - URL-based Parameters
    
    /// The request URL `String`, if initialized using the URL-based approach.
    private let url: String?
    
    /// The HTTP method to be used for the request (e.g., `.get`, `.post`).
    private let method: HTTPMethod
    
    /// Optional **query parameters** to be appended to the URL.
    private let queryParameters: Parameters?
    
    /// Optional **body parameters** to be sent in the request body.
    private let bodyParameters: Parameters?
    
    /// Optional **custom headers** for the request.
    private let headers: HTTPHeaders?
    
    /// The number of **retry attempts** in case of failure.
    private let retryCount: Int
    
    /// The caching policy applied to the request.
    private let cachePolicy: CachePolicy?
    
    // MARK: - RequestConfig-based Parameters
    
    /// The `RequestConfig` instance, if initialized using the `RequestConfig`-based approach.
    private let requestConfig: RequestConfig?
    
    /// A **flag** to determine which initialization method was used.
    ///
    /// - `true`: The request was initialized using `RequestConfig`.
    /// - `false`: The request was initialized using URL-based parameters.
    private let useRequestConfig: Bool
    
    // MARK: - Initializers
    
    /// **Initializes a URL-based `ChainRequest`.**
    ///
    /// - Parameters:
    ///   - networking: The `Networking` instance handling the request.
    ///   - url: The URL `String` to send the request to.
    ///   - method: The HTTP method to use (default: `.get`).
    ///   - queryParameters: Optional query parameters (default: `nil`).
    ///   - bodyParameters: Optional body parameters (default: `nil`).
    ///   - headers: Optional HTTP headers (default: `nil`).
    ///   - retryCount: The number of retry attempts (default: `0`).
    ///   - cachePolicy: The caching policy (default: `nil`).
    ///
    /// - Note:
    ///   - Use this initializer when making direct API requests with explicit parameters.
    ///   - The request details are stored within the instance and executed when `responseDecodable(...)` is called.
    public init(networking: Networking, url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, retryCount: Int = 0, cachePolicy: CachePolicy? = nil) {
        self.networking = networking
        self.url = url
        self.method = method
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.headers = headers
        self.retryCount = retryCount
        self.cachePolicy = cachePolicy
        /// RequestConfig-based parameters are set to nil
        self.requestConfig = nil
        self.useRequestConfig = false
    }
    
    /// **Initializes a RequestConfig-based `ChainRequest`.**
    ///
    /// - Parameters:
    ///   - networking: The `Networking` instance handling the request.
    ///   - config: The `RequestConfig` defining the request details.
    ///   - retryCount: The number of retry attempts (default: `0`).
    ///   - cachePolicy: The caching policy (default: `nil`).
    ///
    /// - Note:
    ///   - Use this initializer when working with pre-configured request objects.
    ///   - The `RequestConfig` object provides a structured way to define API calls.
    public init(networking: Networking, config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil) {
        self.networking = networking
        self.requestConfig = config
        self.retryCount = retryCount
        self.cachePolicy = cachePolicy
        /// URL-based parameters are set to nil
        self.url = nil
        self.method = .get
        self.queryParameters = nil
        self.bodyParameters = nil
        self.headers = nil
        self.useRequestConfig = true
    }
    
}

// MARK: - Response Handling

// MARK: - Decodable Type (`T`) Response
extension ChainRequest {
    
    /// Executes a network request and decodes the response body into the specified `Decodable` type.
    ///
    /// - This method supports both `RequestConfig`-based requests and direct URL-based requests,
    ///   choosing the appropriate mechanism depending on how the request was initialized.
    /// - The completion handler is invoked with a fully constructed `NetworkingResponse<T>`
    ///   that contains either the decoded model or an appropriate `NetworkError`.
    ///
    /// - Parameters:
    ///   - type: The type of model to decode from the response body.
    ///           - Must conform to `Decodable`.
    ///
    ///   - queue: The `DispatchQueue` on which the `completion` handler is executed (default: `.main`).
    ///            - Set to `.main` for UI updates or use a background queue for processing.
    ///
    ///   - decoder: The `JSONDecoder` used to decode the response data (default: `JSONDecoder()`).
    ///              - Can be customized for specific date decoding strategies, key decoding, etc.
    ///
    ///   - completion: A closure called with a `NetworkingResponse<T>` containing:
    ///                 - `.success(T)`: The decoded model from the response body.
    ///                 - `.failure(NetworkError)`: The error describing what went wrong during the request or decoding.
    ///
    /// - Returns:
    ///   - `Self`, allowing for fluent chaining of request steps.
    ///
    /// - Note:
    ///   - Automatically chooses between `requestConfig`-driven requests or manual URL-based configuration.
    ///   - This function does not throw errors directly; instead, all outcomes are delivered through the completion handler.
    ///   - If a request is misconfigured (e.g. missing URL or RequestConfig), the function gracefully returns a `.failure(...)`.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   ChainRequest(networking: networking, url: URL(string: "https://api.example.com/user")!)
    ///       .responseDecodable(of: UserProfile.self) { response in
    ///           switch response.result {
    ///           case .success(let user):
    ///               print("Fetched user:", user)
    ///           case .failure(let error):
    ///               print("Failed to fetch user:", error)
    ///           }
    ///       }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Completion is dispatched on the specified `queue`, ensuring thread-safety when integrating with UI or other logic.
    ///   - Internally safe from data races, as all networking operations are performed asynchronously.
    @discardableResult
    public func responseDecodable<T: Decodable>(of type: T.Type, queue: DispatchQueue = .main, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<T>) -> Void) -> Self {
        if useRequestConfig {
            /// RequestConfig-based request execution
            guard let config = requestConfig else {
                /// Handle missing configuration
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.invalidRequest))
                queue.async {
                    completion(networkingResponse)
                }
                return self
            }
            /// Perform request using `RequestConfig`
            networking.request(config, retryCount: retryCount, cachePolicy: cachePolicy, decoder: decoder) { networkingResponse in
                queue.async {
                    completion(networkingResponse)
                }
            }
        } else {
            /// URL-based request execution
            guard let requestURL = url else {
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.invalidURL))
                queue.async {
                    completion(networkingResponse) /// Handle missing URL
                }
                return self
            }
            /// Perform request using direct URL parameters
            networking.request(url: requestURL, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, headers: headers, retryCount: retryCount, cachePolicy: cachePolicy, decoder: decoder) { networkingResponse in
                queue.async {
                    completion(networkingResponse)
                }
            }
        }
        return self
    }
    
}

// MARK: - Void Response
extension ChainRequest {
    
    /// Executes a network request that expects no meaningful response body (e.g., `204 No Content`).
    ///
    /// - This method is typically used for API endpoints that return no response payload,
    ///   such as logout operations, DELETE requests, or empty success responses.
    /// - Internally, it leverages `responseDecodable` by decoding into a placeholder `VoidPlaceholder` type,
    ///   and maps that to `Void` for clean caller semantics.
    ///
    /// - Parameters:
    ///
    ///   - queue: The `DispatchQueue` on which the completion handler will be executed (default: `.main`).
    ///
    ///   - decoder: A `JSONDecoder` instance used for decoding the response body (default: `JSONDecoder()`).
    ///              - Even though the server is expected to return no content, the decoder is required for consistency.
    ///
    ///   - completion: A closure invoked when the request completes, delivering a `NetworkingResponse<Void>`:
    ///                 - `.success(Void)`: The request succeeded and returned no data.
    ///                 - `.failure(NetworkError)`: The request failed due to network or decoding issues.
    ///
    /// - Returns:
    ///   - `Self`, to support method chaining.
    ///
    /// - Note:
    ///   - This method is ideal for APIs that return a status code with no content (e.g., HTTP 204).
    ///   - Internally decodes a `VoidPlaceholder` to conform with decoding pipeline, then maps it to `Void`.
    ///   - Make sure to dispatch back to the main thread if the `completion` interacts with UI components.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   ChainRequest(networking: networking, url: URL(string: "https://api.example.com/logout")!)
    ///       .responseVoid { response in
    ///           switch response.result {
    ///           case .success:
    ///               print("Logout successful")
    ///           case .failure(let error):
    ///               print("Logout failed:", error)
    ///           }
    ///       }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is thread-safe.
    ///   - The `completion` is invoked on the specified `queue` (default: `.main`).
    ///     If performing UI updates, ensure execution occurs on the main thread.
    @discardableResult
    public func responseVoid(queue: DispatchQueue = .main, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<Void>) -> Void) -> Self {
        self.responseDecodable(of: VoidPlaceholder.self, queue: queue, decoder: decoder) { networkResponse in
            let voidResult: Result<Void, NetworkError> = networkResponse.result.map { _ in () }
            let response = NetworkingResponse<Void>(request: networkResponse.request, response: networkResponse.response, data: networkResponse.data, result: voidResult)
            completion(response)
        }
        return self
    }
    
}

// MARK: – Data Response
extension ChainRequest {
    
    /// Returns the raw response body as `Data`.
    ///
    /// - This method is useful when the caller wants to manually parse or inspect the raw response payload,
    ///   such as binary content, images, logs, or custom-encoded formats.
    ///
    /// - Parameters:
    ///
    ///   - queue: The `DispatchQueue` on which the `completion` block will be executed (default: `.main`).
    ///            - Choose `.global()` or `.utility` if background processing is preferred.
    ///
    ///   - completion: A closure invoked with a `NetworkingResponse<Data>` containing:
    ///                 - `.success(Data)`: If raw response data is available.
    ///                 - `.failure(NetworkError)`: If the request failed or no data was returned.
    ///
    /// - Returns:
    ///   - `Self`, allowing method chaining.
    ///
    /// - Note:
    ///   - Internally uses `.responseDecodable(of: Data.self)` to retrieve the raw response bytes.
    ///   - This method is ideal when working with non-JSON APIs or binary data responses.
    ///   - If no data is received and no error is present, `.noData` will be returned as the failure case.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   networking.request(
    ///       url: URL(string: "https://api.example.com/user")!,
    ///       method: .get)
    ///       .responseData { response in
    ///           switch response.result {
    ///           case .success(let data):
    ///               print("Received data of size:", data.count)
    ///           case .failure(let error):
    ///               print("Failed to decode string:", error)
    ///           }
    ///       }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is thread-safe.
    ///   - The `completion` closure will be called on the specified `queue`. Use `DispatchQueue.main.async` for UI updates.
    @discardableResult
    public func responseData(queue: DispatchQueue = .main, completion: @escaping (NetworkingResponse<Data>) -> Void) -> Self {
        /// Internally re-use the existing `.responseDecodable(of: Data.self)` helper
        /// to retrieve the raw binary buffer from the network response.
        self.responseDecodable(of: Data.self, queue: queue) { dataResponse in
            /// Transform the response into a `Result<Data, NetworkError>` while preserving any errors.
            let rawResult: Result<Data, NetworkError> = {
                if let error = dataResponse.error {
                    /// Propagate the error directly if one occurred during the request or decoding.
                    return .failure(error)
                } else if let rawData = dataResponse.data {
                    /// If raw data is available and no error occurred, return it as a success./
                    return .success(rawData)
                } else {
                    /// No data and no specific error — treat this as an unexpected empty response./
                    return .failure(.noData)
                }
            }()
            /// Re-wrap the result into a new `NetworkingResponse<Data>` preserving
            /// request metadata, HTTP response, and raw data if present.
            let response = NetworkingResponse<Data>(
                request:  dataResponse.request,
                response: dataResponse.response,
                data:     dataResponse.data,
                result:   rawResult
            )
            /// Dispatch the completion handler on the specified queue (default: `.main`)
            queue.async {
                completion(response)
            }
        }
        return self
    }
    
}

// MARK: – String Response
extension ChainRequest {
    
    /// Decodes the HTTP response body into a `String` using the specified string encoding.
    ///
    /// This method is useful when the server returns plain text responses (e.g., HTML, logs, or plain text messages).
    /// Internally, it first retrieves the raw response `Data` and attempts to decode it into a `String`.
    /// If decoding fails or the data is missing, an appropriate `NetworkError` is returned.
    ///
    /// - Parameters:
    ///
    ///   - encoding: The string encoding to use for decoding the response data (default: `.utf8`).
    ///               - Common values include `.utf8`, `.ascii`, `.isoLatin1`, depending on the server's content encoding.
    ///
    ///   - queue: The `DispatchQueue` on which the `completion` handler will be executed (default: `.main`).
    ///            - Use `.main` if the result needs to update the UI.
    ///            - For background processing, consider passing a background queue.
    ///
    ///   - completion: A closure that handles the final result of the response decoding.
    ///                 - The closure receives a `NetworkingResponse<String>`:
    ///                   - `.success(String)`: The decoded response string.
    ///                   - `.failure(NetworkError)`: A decoding or networking error.
    ///
    /// - Returns:
    ///   - Returns `self` to allow for **fluent chaining** of additional response handlers.
    ///     This enables concise and composable request syntax like:
    ///     `.responseString { ... }.responseJSON { ... }`
    ///
    /// - Note:
    ///   - This method is ideal for responses that are **not JSON-encoded**, such as:
    ///     - HTML documents
    ///     - Plain text API error messages
    ///     - Markdown or log files
    ///   - If the response `Data` is empty or `nil`, `.noData` is returned.
    ///   - If decoding fails due to invalid encoding, `.decodingError` is returned.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   networking.request(
    ///       url: URL(string: "https://api.example.com/user")!,
    ///       method: .get)
    ///       .responseString { response in
    ///           switch response.result {
    ///           case .success(let string):
    ///               print("Received string:", string)
    ///           case .failure(let error):
    ///               print("Failed to decode string:", error)
    ///           }
    ///       }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - The completion handler is dispatched on the specified `queue`, which defaults to `.main`.
    ///   - Internally safe for concurrent requests and does not mutate shared state.
    @discardableResult
    public func responseString(encoding: String.Encoding = .utf8, queue: DispatchQueue = .main, completion: @escaping (NetworkingResponse<String>) -> Void) -> Self {
        /// Internally calls `.responseDecodable(of: Data.self)` to retrieve the raw response data.
        /// This allows reuse of the existing response decoding infrastructure while bypassing JSON decoding.
        self.responseDecodable(of: Data.self, queue: queue, decoder: JSONDecoder()) { dataResponse in
            /// A container to hold the result of decoding the raw data into a string.
            let stringResult: Result<String, NetworkError>
            /// Check if response contains any data.
            if let rawData = dataResponse.data {
                /// Attempt to decode the raw bytes into a `String` using the specified encoding.
                if let wrappedString = String(data: rawData, encoding: encoding) {
                    stringResult = .success(wrappedString)
                } else {
                    /// If decoding fails (e.g., wrong encoding), return a decoding error.
                    stringResult = .failure(.decodingError(
                        NSError(domain: "ChainRequest", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "String decoding failed"])
                    ))
                }
            } else {
                /// No data was returned by the server; return `.noData` error.
                stringResult = .failure(.noData)
            }
            /// Wrap the result and original metadata into a `NetworkingResponse<String>`.
            let stringResponse = NetworkingResponse<String>(
                request: dataResponse.request,
                response: dataResponse.response,
                data: dataResponse.data,
                result: stringResult
            )
            /// Dispatch the completion callback to the specified queue (default: `.main`).
            queue.async {
                completion(stringResponse)
            }
        }
        return self
    }
    
}
