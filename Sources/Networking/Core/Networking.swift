//
//  Networking.swift
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

// MARK: - Networking

/// `Networking` is a powerful and structured network client for handling HTTP requests, downloads, and uploads.
///
/// - Features:
///   - **Asynchronous HTTP Requests**: Supports `GET`, `POST`, `PUT`, `DELETE`, and custom HTTP methods.
///   - **Request Interception**: Modify requests before execution, attach authentication tokens, or handle retries.
///   - **SSL Pinning Support**: Ensures secure communication by validating server certificates.
///   - **Logging & Debugging**: Integrated `NetworkLogger` to capture request and response details.
///   - **Response Caching**: Stores and retrieves cached responses to reduce redundant network calls.
///   - **File Handling**: Supports both file uploads and downloads with progress tracking.
///   - **Network Awareness**: `ConnectionMonitor` prevents unnecessary requests when offline.
///
/// - Note:
///   - This class abstracts low-level `URLSession` management and provides a clean API for handling HTTP operations.
///   - Designed for flexibility, allowing developers to inject custom interceptors, caching mechanisms, and logging solutions.
///
/// - Example:
///   ```swift
///   let networking = Networking()
///   let url = URL(string: "https://api.example.com/data")!
///   Task {
///       do {
///           let response: MyModel = try await networking.request(url: url)
///           print(response)
///       } catch {
///           print("Request failed: \(error)")
///       }
///   }
///   ```
open class Networking {
    
    /// The `RequestProtocol` instance responsible for executing HTTP requests.
    /// Handles modifications, retries, caching, and logging.
    var request: RequestProtocol
    
    /// The `URLSession` instance used for all network communication.
    /// Manages HTTP and HTTPS requests with custom session configurations.
    private(set) var urlSession: URLSession
    
    /// An optional `RequestInterceptor` for modifying or retrying requests.
    /// Typically used for authentication, logging, and request retry logic.
    private(set) var interceptor: RequestInterceptor?
    
    /// An optional `NetworkLogger` for logging network activity.
    /// Useful for debugging network requests and responses.
    private(set) var logger: NetworkLogger?
    
    /// The `DownloaderProtocol` instance for handling file downloads.
    /// Supports large file downloads, resumable transfers, and progress tracking.
    var downloader: DownloaderProtocol
    
    /// The `UploaderProtocol` instance for handling file uploads.
    /// Supports background uploads, multipart uploads, and tracking upload progress.
    var uploader: UploaderProtocol
    
    /// An optional `ResponseCaching` instance for storing and retrieving cached responses.
    /// Improves performance by reducing redundant network requests.
    private(set) var cache: ResponseCaching?
    
    /// A `ConnectionMonitor` to track network availability.
    /// Ensures efficient network request handling based on connectivity status.
    private(set) var connectionMonitor: ConnectionMonitor

    /// Initializes a network client with a specified session configuration, optional interceptor, downloader, uploader and cache.
    ///
    /// - This initializer sets up a fully configurable network client, allowing customization of:
    ///   - **Session Configuration**: Defines request policies, timeout settings, caching behavior, and background support.
    ///   - **Request Interceptor**: Allows modification, authentication, or retry logic before sending requests.
    ///   - **SSL Pinning**: Provides secure communication by verifying the server's certificate.
    ///   - **Task Management**: Uses a dedicated `DispatchQueue` to efficiently manage network requests.
    ///   - **Response Caching**: Enables caching for faster responses and reduced network usage.
    ///   - **Logging**: Captures request/response details for debugging.
    ///
    /// - Parameters:
    ///   - configuration: The `URLSessionConfiguration` to be used for network requests.
    ///                    - Defaults to `.default`, which provides standard network policies.
    ///   - interceptor: An optional `RequestInterceptor` for modifying requests or handling retries.
    ///                  - Useful for authentication, logging, and error recovery.
    ///   - pinningDelegate: A `PinningURLSessionDelegate` used for **SSL certificate pinning**.
    ///                      - Defaults to a new instance, ensuring **secure HTTPS communication**.
    ///                      - If `nil`, SSL pinning is disabled.
    ///   - rootQueue: A `DispatchQueue` for handling network tasks efficiently.
    ///                - Defaults to a **serial queue**, preventing concurrent modifications.
    ///   - cache: An optional `ResponseCaching` instance for storing and retrieving cached responses.
    ///            - Helps improve performance by avoiding redundant network requests.
    ///
    /// - Note:
    ///   - This **convenience initializer** creates a new `URLSession` instance and calls the **designated initializer**.
    ///   - **SSL Certificate Pinning**: If a `PinningURLSessionDelegate` is provided, secure server validation is enabled.
    ///   - If `cache` is `nil`, responses will not be stored and must be fetched on every request.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let sessionConfig = URLSessionConfiguration.default
    ///   let cache = InMemoryResponseCache()
    ///
    ///   let networkClient = Networking(
    ///       configuration: sessionConfig,
    ///       interceptor: AuthInterceptor(),
    ///       cache: cache
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This initializer should be called **on the main thread** or a background thread before making network requests.
    ///   - The `rootQueue` ensures **safe execution** of network tasks without blocking the main thread.
    public convenience init(configuration: URLSessionConfiguration = .default, interceptor: RequestInterceptor? = nil, pinningDelegate: PinningURLSessionDelegate? = PinningURLSessionDelegate(), rootQueue: DispatchQueue = DispatchQueue(label: "networking.rootQueue"), cache: ResponseCaching? = nil) {
        /// Ensure that the provided `rootQueue` is not the main queue unless explicitly intended.
        /// Using a custom queue helps avoid blocking the main thread for network operations.
        let serialRootQueue = (rootQueue === DispatchQueue.main) ? rootQueue : DispatchQueue(label: rootQueue.label, target: rootQueue)
        /// Create an `OperationQueue` to handle delegate callbacks.
        /// This queue is assigned a single concurrent operation (`maxConcurrentOperationCount = 1`) to ensure serial execution.
        let delegateQueue = OperationQueue()
        delegateQueue.name = "\(serialRootQueue.label).delegateQueue"
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.underlyingQueue = serialRootQueue
        let session = URLSession(configuration: configuration, delegate: pinningDelegate, delegateQueue: delegateQueue)
        self.init(session: session, pinningDelegate: pinningDelegate, interceptor: interceptor, cache: cache)
    }
    
    /// Initializes a network client with a given `URLSession`, optional interceptor, downloader, uploader and cache.
    /// Designated initializer that accepts a custom `URLSession`.
    ///
    /// - This initializer allows for greater flexibility by enabling users to provide their own `URLSession` configuration,
    ///   which may include a **custom delegate**, additional security policies, or specific network settings.
    /// - It sets up **request interception**, **response caching**, and **logging**, if provided.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` instance to be used for all network requests.
    ///              - You can configure this session to set timeout intervals, caching policies, and support for background transfers.
    ///              - If SSL pinning is needed, make sure to provide a session initialized with a delegate that validates certificates.
    ///   - pinningDelegate: An optional `PinningURLSessionDelegate` used to handle SSL certificate pinning.
    ///                      - Defaults to `nil`, which disables SSL pinning unless the provided session already has a delegate.
    ///                      - Provide a delegate instance to enforce secure HTTPS communication with certificate validation.
    ///   - interceptor: An optional `RequestInterceptor` used to adapt requests or handle retry logic.
    ///                  - Can be useful for tasks like authentication token injection, request modification, or retry policies.
    ///   - cache: An optional `ResponseCaching` instance for storing and retrieving cached responses.
    ///            - Helps improve performance by avoiding redundant network requests.
    ///            - If `nil`, caching is disabled, and every request will fetch fresh data.
    ///
    /// - Note:
    ///   - This initializer allows users to provide a **custom `URLSession`**, which may include their own delegate.
    ///   - **SSL Pinning is NOT enabled** in this initializer unless the provided `session` has a delegate configured for it.
    ///   - If SSL pinning is required, use the **convenience initializer** that accepts a `PinningURLSessionDelegate` or manually configure a delegate.
    ///   - The provided session should be **properly configured** before use, as this class does not alter its settings.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let sessionConfig = URLSessionConfiguration.default
    ///   let session = URLSession(configuration: sessionConfig) /// No custom delegate
    ///
    ///   let networkClient = Networking(
    ///       session: session,
    ///       interceptor: AuthInterceptor(),
    ///       cache: InMemoryResponseCache()
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This initializer should be called **on the main thread** or a **background thread** before making network requests.
    ///   - Network tasks will be executed asynchronously, ensuring that the main thread remains responsive.
    public init(session: URLSession, pinningDelegate: PinningURLSessionDelegate? = nil, interceptor: RequestInterceptor? = nil, cache: ResponseCaching? = nil) {
        self.urlSession = session
        self.interceptor = interceptor
        self.cache = cache
        self.logger = NetworkLogger()
        self.connectionMonitor = ConnectionMonitor()
        self.downloader = Downloader(session: session, pinningDelegate: pinningDelegate, interceptor: interceptor, logger: logger, connectionMonitor: connectionMonitor)
        self.uploader = Uploader(session: session, pinningDelegate: pinningDelegate, interceptor: interceptor, logger: logger, connectionMonitor: connectionMonitor)
        self.request = Request(urlSession: session, interceptor: interceptor, cache: cache, logger: logger, connectionMontitor: connectionMonitor)
    }
    
}

// MARK: - Request - Async/Await Request
extension Networking {
    
    /// Sends an HTTP request to the specified URL and decodes the response into a given `Decodable` type (`T`).
    ///
    /// - This method simplifies network requests by allowing direct invocation with a `URL`, HTTP method, parameters, and headers.
    /// - It constructs a `RequestConfig` internally and delegates request execution to another method.
    /// - Supports **query parameters**, **body parameters**, **custom headers**, **caching**, and **automatic retries**.
    ///
    /// - Parameters:
    ///   - url: The URL `String` to send the request to.
    ///   - method: The HTTP method (`GET`, `POST`, `PUT`, etc.). Defaults to `.get`.
    ///             - Determines whether parameters are appended as query items (`GET`) or sent in the body (`POST`, `PUT`).
    ///   - queryParameters: Optional key-value query parameters that are appended to the request URL.
    ///                      - Used for requests like `GET` where parameters should be part of the URL.
    ///   - bodyParameters: Optional key-value parameters that are sent in the request body.
    ///                     - Applied for `POST`, `PUT`, `PATCH`, and `DELETE` requests.
    ///                     - Encoded as JSON unless specified otherwise.
    ///   - headers: Optional dictionary of HTTP headers.
    ///              - If `nil`, default headers may be used (e.g., `"Content-Type": "application/json"`).
    ///   - retryCount: The number of retry attempts in case of failure. Defaults to `0`.
    ///                 - If greater than `0`, the request will be retried automatically based on error type.
    ///   - cachePolicy: An optional `CachePolicy` that determines how the request interacts with caching.
    ///                  - If `nil`, the default cache behavior is applied.
    ///   - decoder: The `JSONDecoder` instance used to decode the response data. Defaults to `JSONDecoder()`.
    ///              - Can be customized to use different date decoding strategies or key decoding strategies.
    ///
    /// - Returns: A `NetworkingResponse<T>` containing the decoded object or an error describing the failure.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidRequest`: If the request configuration fails (e.g., malformed URL, missing parameters).
    ///   - `NetworkError.requestFailed(statusCode:data:)`: If the request fails due to a non-2xx HTTP status code.
    ///   - `NetworkError.decodingError(error)`: If the response cannot be decoded into the expected `T` type.
    ///   - `NetworkError.unknown(error)`: If an unexpected error occurs.
    ///   - `NetworkError.noInternetConnection`: If there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching**: If a `CachePolicy` is provided, the response may be retrieved from or stored in cache.
    ///   - **Retries**: If the request fails due to temporary errors (e.g., `500 Internal Server Error`), it will retry up to `retryCount` times.
    ///   - **Asynchronous Execution**: This method is marked `async`, meaning it must be called from an `async` context.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   struct User: Decodable {
    ///       let id: Int
    ///       let name: String
    ///   }
    ///
    ///   let networking = Networking()
    ///   let url = URL(string: "https://api.example.com/user")!
    ///
    ///   Task {
    ///       do {
    ///           let response: NetworkingResponse<User> = try await networking.request(url: url)
    ///           if let user = response.value {
    ///               print("User data: \(user)")
    ///           } else if let error = response.error {
    ///               print("Error: \(error)")
    ///           }
    ///       } catch {
    ///           print("Unexpected failure: \(error)")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is **asynchronous** and should be executed within an `async` context.
    ///   - UI updates (e.g., displaying results) should be performed on the **main thread** after awaiting the response.
    public func request<T: Decodable>(url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, decoder: JSONDecoder = JSONDecoder()) async throws -> NetworkingResponse<T> {
        /// Construct the request configuration with the provided parameters
        let requestConfig = RequestConfig(url: url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, headers: headers)
        /// Forward the request to the main request handling function
        return try await request.request(requestConfig, retryCount: retryCount, cachePolicy: cachePolicy, decoder: decoder)
    }
    
    /// Sends an HTTP request using the given `RequestConfig` and decodes the response into a specified `Decodable` type (`T`).
    ///
    /// - This method is responsible for executing network requests based on a `RequestConfig`,
    ///   handling caching, retries, and decoding the response into the expected type.
    ///
    /// - Parameters:
    ///   - config: The `RequestConfig` object containing request details:
    ///             - `url`: The target API endpoint.
    ///             - `method`: The HTTP method (e.g., `.get`, `.post`, `.put`).
    ///             - `parameters`: Optional query/body parameters.
    ///             - `headers`: Custom HTTP headers.
    ///   - retryCount: The number of retry attempts in case of failure. Defaults to `0`.
    ///                 - If greater than `0`, the request will be retried automatically based on error type.
    ///   - cachePolicy: An optional `CachePolicy` determining how the request interacts with caching.
    ///                  - If `nil`, the default cache behavior is applied.
    ///   - decoder: The `JSONDecoder` instance used to decode the response data. Defaults to `JSONDecoder()`.
    ///              - Can be customized to use different date decoding strategies or key decoding strategies.
    ///
    /// - Returns: A `NetworkingResponse<T>` containing either the successfully decoded value or a failure with detailed error information.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidRequest`: If the request configuration fails (e.g., malformed URL, missing parameters).
    ///   - `NetworkError.requestFailed(statusCode:data:)`: If the request fails due to a non-2xx HTTP status code.
    ///   - `NetworkError.decodingError(error)`: If the response cannot be decoded into the expected `T` type.
    ///   - `NetworkError.unknown(error)`: If an unexpected error occurs.
    ///   - `NetworkError.noInternetConnection`: If there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching**: If a `CachePolicy` is provided, the response may be retrieved from or stored in cache.
    ///   - **Retries**: If the request fails due to temporary errors (e.g., `500 Internal Server Error`), it will retry up to `retryCount` times.
    ///   - **Interceptor Support**: If an interceptor is provided, it can modify or retry the request before execution.
    ///   - **Asynchronous Execution**: This method is marked `async`, meaning it must be called from an `async` context.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   struct Product: Decodable {
    ///       let id: Int
    ///       let name: String
    ///   }
    ///
    ///   let networking = Networking()
    ///   let config = RequestConfig(
    ///       url: URL(string: "https://api.example.com/products")!,
    ///       method: .get
    ///   )
    ///
    ///   Task {
    ///       do {
    ///           let response: NetworkingResponse<[Product]> = try await networking.request(config)
    ///           if let products = response.value {
    ///               print("Fetched products: \(products)")
    ///           } else if let error = response.error {
    ///               print("Failed with: \(error)")
    ///           }
    ///       } catch {
    ///           print("Unexpected error: \(error)")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is **asynchronous** and should be executed within an `async` context.
    ///   - UI updates (e.g., displaying results) should be performed on the **main thread** after awaiting the response.
    public func request<T: Decodable>(_ config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, decoder: JSONDecoder = JSONDecoder()) async throws -> NetworkingResponse<T> {
        return try await request.request(config, retryCount: retryCount, cachePolicy: cachePolicy, decoder: decoder)
    }
    
}

// MARK: - Request - Completion Handler
extension Networking {
    
    /// Sends an HTTP request to the specified URL and decodes the response into a given `Decodable` type (`T`), using a completion handler.
    ///
    /// - This method allows performing an HTTP request with customizable parameters and handles response decoding.
    /// - Supports **query parameters**, **body parameters**, **custom headers**, **caching**, and **automatic retries**.
    /// - Uses a completion handler instead of `async/await`, making it suitable for non-async contexts (e.g., UIKit-based applications).
    ///
    /// - Parameters:
    ///   - url: The URL `String` to send the request to.
    ///   - method: The HTTP method (`GET`, `POST`, `PUT`, etc.). Defaults to `.get`.
    ///             - Determines whether parameters are appended as query items (`GET`) or sent in the body (`POST`, `PUT`).
    ///   - queryParameters: Optional key-value query parameters that are appended to the request URL.
    ///                      - Used for requests like `GET`, where parameters should be part of the URL.
    ///   - bodyParameters: Optional key-value parameters that are sent in the request body.
    ///                     - Applied for `POST`, `PUT`, `PATCH`, and `DELETE` requests.
    ///                     - Encoded as JSON unless specified otherwise.
    ///   - headers: Optional dictionary of HTTP headers.
    ///              - If `nil`, default headers may be used (e.g., `"Content-Type": "application/json"`).
    ///   - retryCount: The number of retry attempts in case of failure. Defaults to `0`.
    ///                 - If greater than `0`, the request will be retried automatically based on error type.
    ///   - cachePolicy: An optional `CachePolicy` determining how the request interacts with caching.
    ///                  - If `nil`, the default cache behavior is applied.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: The `JSONDecoder` instance used to decode the response data. Defaults to `JSONDecoder()`.
    ///              - Can be customized to use different date decoding strategies or key decoding strategies.
    ///   - completion: A closure that receives a `NetworkingResponse<T>`, containing either a decoded value or a `NetworkError`.
    ///                 - `.success(T)`: The successfully decoded response object.
    ///                 - `.failure(NetworkError)`: An error describing why the request failed.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidRequest`: If the request configuration fails (e.g., malformed URL, missing parameters).
    ///   - `NetworkError.requestFailed(statusCode:data:)`: If the request fails due to a non-2xx HTTP status code.
    ///   - `NetworkError.decodingError(error)`: If the response cannot be decoded into the expected `T` type.
    ///   - `NetworkError.unknown(error)`: If an unexpected error occurs.
    ///   - `NetworkError.noInternetConnection`: If there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching**: If a `CachePolicy` is provided, the response may be retrieved from or stored in cache.
    ///   - **Retries**: If the request fails due to temporary errors (e.g., `500 Internal Server Error`), it will retry up to `retryCount` times.
    ///   - **Completion-Based API**: This method is useful in **non-async contexts**, such as UIKit-based applications.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   struct User: Decodable {
    ///       let id: Int
    ///       let name: String
    ///   }
    ///
    ///   networking.request(
    ///       url: URL(string: "https://api.example.com/user")!,
    ///       method: .get,
    ///       completion: { response in
    ///           switch response.result {
    ///           case .success(let user):
    ///               print("User data: \(user)")
    ///           case .failure(let error):
    ///               print("Request failed with error: \(error)")
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - The network request is executed asynchronously and is non-blocking.
    ///   - The `completion` closure is called on the provided `queue`. If you are updating UI from the completion, ensure it runs on `.main`.
    public func request<T: Decodable>(url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<T>) -> Void) {
        /// Construct the request configuration with the provided parameters
        let requestConfig = RequestConfig(url: url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, headers: headers)
        /// Forward the request execution to the main request handling function
        request.request(requestConfig, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
    }
    
    /// Sends an HTTP request using the given `RequestConfig` and decodes the response into a specified `Decodable` type (`T`), using a completion handler.
    ///
    /// - This method executes a network request based on the provided `RequestConfig` and processes the response.
    /// - It supports **caching**, **automatic retries**, and **custom decoding** for handling API responses.
    /// - Uses a **completion handler** instead of `async/await`, making it suitable for non-async contexts (e.g., UIKit-based applications).
    ///
    /// - Parameters:
    ///   - config: The `RequestConfig` object containing request details:
    ///       - `url`: The target API endpoint.
    ///       - `method`: The HTTP method (e.g., `.get`, `.post`, `.put`).
    ///       - `parameters`: Optional query/body parameters.
    ///       - `headers`: Custom HTTP headers.
    ///   - retryCount: The number of retry attempts in case of failure. Defaults to `0`.
    ///                 - If greater than `0`, the request will be retried automatically based on error type.
    ///   - cachePolicy: An optional `CachePolicy` determining how the request interacts with caching.
    ///                  - If `nil`, the default cache behavior is applied.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: The `JSONDecoder` instance used to decode the response data. Defaults to `JSONDecoder()`.
    ///              - Can be customized to use different date decoding strategies or key decoding strategies.
    ///   - completion: A closure that receives a `NetworkingResponse<T>` containing the decoded value or a `NetworkError`.
    ///                 - `.success(T)`: The successfully decoded response object.
    ///                 - `.failure(NetworkError)`: An error describing why the request failed.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidRequest`: If the request configuration fails (e.g., malformed URL, missing parameters).
    ///   - `NetworkError.requestFailed(statusCode:data:)`: If the request fails due to a non-2xx HTTP status code.
    ///   - `NetworkError.decodingError(error)`: If the response cannot be decoded into the expected `T` type.
    ///   - `NetworkError.unknown(error)`: If an unexpected error occurs.
    ///   - `NetworkError.noInternetConnection`: If there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching**: If a `CachePolicy` is provided, the response may be retrieved from or stored in cache.
    ///   - **Retries**: If the request fails due to temporary errors (e.g., `500 Internal Server Error`), it will retry up to `retryCount` times.
    ///   - **Completion-Based API**: This method is useful in **non-async contexts**, such as UIKit-based applications.
    ///   - **Interceptor Support**: If an interceptor is provided, it can modify or retry the request before execution.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   struct User: Decodable {
    ///       let id: Int
    ///       let name: String
    ///   }
    ///
    ///   let requestConfig = RequestConfig(url: URL(string: "https://api.example.com/user")!)
    ///
    ///   networking.request(requestConfig) { response in
    ///       switch response.result {
    ///       case .success(let user):
    ///           print("Received user: \(user)")
    ///       case .failure(let error):
    ///           print("Request failed with error: \(error)")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - The request is performed asynchronously and does not block the calling thread.
    ///   - The `completion` handler is called on the specified `queue`. Ensure UI updates are dispatched to `.main` if necessary.
    public func request<T: Decodable>(_ config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<T>) -> Void) {
        request.request(config, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
    }
    
}

// MARK: - Chain Request - Request Chaining for Completion
public extension Networking {
    
    /// **Initiates a URL-based chained request.**
    ///
    /// This method allows you to create a `ChainRequest` using direct URL parameters.
    /// Instead of requiring a completion handler, it returns a `ChainRequest` instance,
    /// allowing for a more structured and reusable request flow.
    ///
    /// - Parameters:
    ///   - url: The URL `String` to send the request to.
    ///   - method: The HTTP method to use (default: `.get`).
    ///   - queryParameters: Optional query parameters (default: `nil`).
    ///   - bodyParameters: Optional body parameters (default: `nil`).
    ///   - headers: Optional HTTP headers (default: `nil`).
    ///   - retryCount: The number of retry attempts in case of failure (default: `0`).
    ///   - cachePolicy: An optional `CachePolicy` for caching behavior (default: `nil`).
    ///
    /// - Returns: A `ChainRequest` instance, enabling a **fluent API** style.
    ///
    /// - Note:
    ///   - This approach is useful when dynamically building requests and deferring execution.
    ///   - The returned `ChainRequest` instance must be executed using `.responseDecodable(...)`.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   networking.request(
    ///       url: URL(string: "https://api.example.com/posts")!,
    ///       method: .get
    ///   )
    ///   .responseDecodable(of: [Post].self) { result in
    ///       switch result {
    ///       case .success(let posts):
    ///           print("Fetched posts:", posts)
    ///       case .failure(let error):
    ///           print("Request failed:", error)
    ///       }
    ///   }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is **thread-safe** but does not execute the request immediately.
    ///   - The request execution should be performed on a **background thread**.
    @discardableResult
    func request(url: String, method: HTTPMethod = .get, queryParameters: Parameters? = nil, bodyParameters: Parameters? = nil, headers: HTTPHeaders? = nil, retryCount: Int = 0, cachePolicy: CachePolicy? = nil) -> ChainRequest {
        return ChainRequest(networking: self, url: url, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, headers: headers, retryCount: retryCount, cachePolicy: cachePolicy)
    }
    
    /// **Initiates a RequestConfig-based chained request.**
    ///
    /// This method allows you to create a `ChainRequest` using a `RequestConfig` object.
    /// Instead of requiring a completion handler, it returns a `ChainRequest` instance,
    /// allowing for a **fluent API** style where execution happens later.
    ///
    /// - Parameters:
    ///   - config: The `RequestConfig` object that contains the request details.
    ///   - retryCount: The number of retry attempts in case of failure (default: `0`).
    ///   - cachePolicy: An optional `CachePolicy` for caching behavior (default: `nil`).
    ///
    /// - Returns: A `ChainRequest` instance, enabling a **structured and reusable API request flow**.
    ///
    /// - Note:
    ///   - This approach is ideal for scenarios where API request configurations are **predefined**.
    ///   - The returned `ChainRequest` must be executed using `.responseDecodable(...)`.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let config = RequestConfig(
    ///       url: URL(string: "https://api.example.com/profile")!,
    ///       method: .get,
    ///       headers: HTTPHeaders(["Authorization": "Bearer token"])
    ///   )
    ///
    ///   networking.request(config)
    ///       .responseDecodable(of: User.self) { result in
    ///           switch result {
    ///           case .success(let user):
    ///               print("User profile:", user)
    ///           case .failure(let error):
    ///               print("Failed to fetch user profile:", error)
    ///           }
    ///       }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is **thread-safe** but does not execute the request immediately.
    ///   - The request execution should be performed on a **background thread**.
    @discardableResult
    func request(_ config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil) -> ChainRequest {
        return ChainRequest(networking: self, config: config, retryCount: retryCount, cachePolicy: cachePolicy)
    }
    
}
